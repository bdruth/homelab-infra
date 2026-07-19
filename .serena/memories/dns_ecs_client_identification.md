# DNS: ECS client identification through dnsdist -> Pi-hole

Path is `clients -> dnsdist (192.168.7.3) -> pihole-blue (.2) / pihole-green (.4)`.

## ECS works; don't re-diagnose it

Per-client identification through dnsdist is **functional**. Verified by probe:
a query from 192.168.7.33 via dnsdist is recorded in FTL's `queries` table with
`client = 192.168.7.33`, not dnsdist's IP.

Two settings are load-bearing and must stay as they are:

- `services/dnsdist/dnsdist.conf.j2`: `setECSSourcePrefixV4(32)` / `V6(128)` plus
  `useClientSubnet=true` on the Pi-hole backends. **FTL's `src/edns0.c` silently
  discards any ECS that is not /32 or /128.** dnsdist's default prefix is /24, which
  would break client identification with no error anywhere.
- `services/pihole/pihole.toml.j2`: `dns.EDNS0ECS = true`.

## `/var/log/pihole/pihole.log` is misleading here

dnsmasq logs the raw packet source, so every query reads `from 192.168.7.3`
regardless. FTL's ECS rewrite happens separately and is what drives client
identity. **Check the `queries` table in `/etc/pihole/pihole-FTL.db`, not the
dnsmasq log**, when verifying client attribution. FTL batches DB writes on an
interval, so a probe can take ~60s to appear.

`sqlite3` is not installed on the Pi-holes; use `pihole-FTL sqlite3`.

### Querying the FTL DB over ssh: pipe the SQL via stdin

Inlining SQL inside nested ssh quoting silently returns **zero rows instead of an
error** -- no message, no non-zero exit, just nothing. This produced several
false conclusions in the past (a probe read as "ECS is broken on this node" when
the query had simply never run). Pipe the statement in instead:

```sh
ssh -o LogLevel=ERROR root@<pihole> \
    "pihole-FTL sqlite3 /etc/pihole/pihole-FTL.db" <<< "select ...;"
```

**Always sanity-check the tool before trusting a negative result** --
`select count(*) from queries;` should return ~20M and
`select datetime(max(timestamp),'unixepoch','localtime') from queries;` should
be within the last minute. An empty result from a query you have not validated
is evidence of nothing.

Note also that FTL batches DB writes, so a probe takes up to ~60s to appear;
allow 90s before concluding it is missing. The Pi-holes run in UTC while the
dnsdist nodes are America/Chicago, so timestamps across hosts differ by 5-6h.

## Why parseARPcache is disabled

FTL builds its network/device table from the ARP cache. Because dnsdist fronts both
Pi-holes, every query arrives with dnsdist's MAC (`bc:24:11:27:f6:81`, set in
`infrastructure/dns/dns-ha/dnsdist.tf`), so FTL collapsed ~1870 client addresses onto
one device record and labelled the whole UI with whatever hostname that record last
resolved to (`weewx-pi4.cusack-ruth.name`). This is a *display* artifact only —
group matching keys off client IP via `subnet_match()`, not MAC.

`parse_arp_cache: false` in `services/pihole/vars/main.yml` fixes it. The network
table then repopulates 1:1 with synthetic `ip-<addr>` identifiers. The Network
overview page cannot convey anything useful behind a forwarder, so nothing is lost.

## Per-client policy is codified

`services/pihole/gravity-clients.sql.j2` reconciles the gravity `group` / `client` /
`client_by_group` tables from `pihole_groups` / `pihole_clients` in vars. It is
applied to **both** blue and green — dnsdist load-balances across them, so identical
group state is required or policy varies per query. Adding a device is a data-only
vars change.

Gotcha: the `tr_client_add` trigger force-adds every new client to group 0 (Default),
so the template clears and rebuilds memberships rather than merging.
`pihole_clients_prune` is false, so UI-added clients survive a redeploy.

## Deploy side effect

`services/pihole/main.yml` compares `pihole version --current` against the latest
GitHub release and runs `curl -L https://install.pi-hole.net | bash` when they differ.
**Any deploy touching `services/pihole/**` may also upgrade Pi-hole.** The
`pihole.toml` template task runs after the reinstall, so managed config wins.

## Current DNS topology (post-HA cutover)

`192.168.7.3` is a **keepalived VRRP VIP**, not a container address. It floats across:

- `dns-ha-1` / CT 113 / `192.168.7.12` — VRRP MASTER, priority 150
- `dns-ha-2` / CT 114 / `192.168.7.13` — VRRP BACKUP, priority 100

Unicast VRRP (not multicast — multicast in unprivileged LXC on a Proxmox bridge
has reported split-brain). `vrrp_instance` only, no IPVS: IPVS cannot initialise
in an unprivileged container.

The health check (`/usr/local/bin/check_dnsdist.sh`) performs a real resolution and
carries `weight -60`, so an unhealthy master drops 150->90 and a healthy backup
(100) takes over; if *both* are unhealthy the master keeps the VIP rather than
leaving nothing listening. Measured failover on node death: ~0.6s.

**`dig +short` writes "communications error" to STDOUT, not stderr.** A health check
that only tests for empty output therefore reports healthy when the resolver is
dead. Check dig's exit code *and* require an actual A record (dig exits 0 on
SERVFAIL too).

eero hands out `.3` and never had to change. Its IPv4 secondary is unset; adding
`.13` was judged not worth the mesh reboot it costs.

The original single node (CT 104) has been destroyed; there is no longer any
container holding `.3` as a real address. Everything is codified -- no drift.

`deploy.sh` gates on `dns_ha_1_ip`, `dns_ha_2_ip` **and** the `dns_vip` output.
The VIP check matters on its own: both nodes can be individually healthy while
nobody holds the VIP, which is the failure that actually reaches clients.

Note `ssh_public_keys` is ForceNew on `proxmox_lxc`. Changing it destroys and
recreates the container, so treat an edit as a rolling rebuild of the pair --
one node per apply, never both.

### Cutover timing, if this is ever repeated

Measured interruption was **~5s**, not the ~1s predicted. `ip addr del` is
instant; the cost is keepalived entering `BACKUP (init)` on restart and taking
~3 advert intervals to reach MASTER. A `reload` instead of `restart` would
likely be faster.

Drive container surgery through the Proxmox host with `pct exec`, never by
ssh-ing to the container whose address is being moved -- deleting `.3` over a
session addressed to `.3` kills the control channel and the rollback path with
it. `pct exec` propagates exit codes correctly.

## Encrypted upstream (DoT)

Everything leaving the network is encrypted. Remaining plaintext hops are all
internal: clients -> dnsdist and dnsdist -> Pi-hole are LAN-local, Pi-hole ->
stubby is loopback.

- **Pi-hole -> NextDNS**: via **stubby** on each Pi-hole, `127.0.0.1#5453`
  (`services/pihole/stubby.yml.j2`). This is the main traffic path.
- **dnsdist fallbacks**: DoT on `:853` directly, no extra daemon
  (`tls="openssl"` -- the Debian build sets `--with-gnutls=no`).

NextDNS profile id is **f2da97** (encoded in the low bits of `2a07:a8c0::f2:da97`).
The id **must** appear in the DoT hostname (`f2da97.dns.nextdns.io`) or NextDNS
serves generic unfiltered resolution. The cert carries `DNS:*.dns.nextdns.io`, so
that name validates. This also retires NextDNS "Linked IP", which silently drops
you to an unfiltered profile whenever the WAN address changes.

stubby specifically because: cloudflared's proxy-dns was deprecated Nov 2025 and
stops working for installs updated after 2026-02-02; dnscrypt-proxy is only
packaged from Debian 13. stubby is in bookworm and has **no bootstrap
dependency** -- `address_data` is a literal IP and `tls_auth_name` is a
cert-validation input, not a lookup. That matters because these are the only
resolvers on the network.

Verify encryption with `ss -tnp | grep :853 | grep ESTAB` on a Pi-hole (expect
several) and confirm zero plaintext `:53` to the NextDNS anycast addresses.

## Rolling updates without an outage

`services/dnsdist/main.yml` drains the VIP before restarting dnsdist: if this
node holds it, keepalived is stopped so the peer takes over, dnsdist restarts,
local resolution is confirmed, then keepalived returns. It **refuses to drain
into a void** -- if the peer cannot resolve, the play fails rather than moving
the VIP somewhere that cannot serve it.

keepalived carries `nopreempt` (requires `state BACKUP` on both), so whoever
holds the VIP keeps it until it actually fails. Without it every rolling update
costs two handovers instead of one. A full rolling dnsdist update is therefore a
single ~0.6s handover -- this is what makes the pending 1.7.3 -> current upgrade
practical without a maintenance window.

## Two traps worth remembering

**Ansible conditionals must be boolean.** `regex_search()` returns the matched
string and ansible-core 2.21 rejects it: *"Conditional result (True) was derived
from value of type 'str'"*. Use the `is search(...)` test. **ansible-lint passes
on both forms**, so lint will not catch this -- verify by running it.

**Do not apt-install onto a live Pi-hole to "test" something.** The stubby
package starts listening on `127.0.0.1:53` on install, which collides with
pihole-FTL and left blue with `upstreams = []`. Test on a scratch host, or let
the playbook do it where the ordering is handled.

## dnsdist version and server policy

**2.0.7** from the PowerDNS repo (`bookworm-dnsdist-{{ dnsdist_repo_version }}`,
currently `20`), pinned via `/etc/apt/preferences.d/dnsdist`. Debian bookworm
only ships 1.7.3 (EOL) and there is no dnsdist in bookworm-backports.

Server selection is the **built-in `orderedWrandUntag`**, not a custom Lua
policy. `setServerPolicy(orderedWrandUntag)` -- bare identifier, not a string,
and `setServerPolicy` rather than `setServerPolicyLua`. The old
`orderedwrandom.lua` is deleted; the playbook actively removes it from hosts.

**Moving to 2.1 is a one-line bump of `dnsdist_repo_version`.** With no custom
Lua left there is nothing to break -- 2.1 changed custom policies to return an
*index* into the servers array rather than a server object, which is what made
2.1 unsafe while the custom policy existed.

### The upgrade ordering trap (relevant to any future major bump)

The package must land **before** the config: `orderedWrandUntag` does not exist
on older binaries, and the config dies with `Fatal Lua error: Unable to convert
parameter from nil to ServerPolicy`. That ordering means the new binary briefly
runs the *old* config during the dpkg restart. Harmless going 1.7->2.0; it would
have ServFailed every query going straight to 2.1.

The playbook computes both "package will change" and "config will change" in
`check_mode` *before* touching anything, so the VIP drains ahead of a
dpkg-triggered restart as well as a config change. Verified: a full 1.7.3 ->
2.0.7 upgrade across both nodes produced **zero** unanswered queries.

### `dnsdist --check-config` is not a safety net

It accepts a completely bogus `newServer` key without complaint (tested:
`definitelyNotARealKey=true` -> `Configuration OK!`). Unknown table parameters
warn and continue. This is how `healthCheckMode="lazy"` was silently ignored for
however long the config had it -- the key was only added in 1.8.0, so on 1.7.3
both backends were *actively* health-checked at ~3 probes/sec (~259k/day into
the Pi-hole logs). After the upgrade that rate is zero.

Semantic changes are likewise invisible to it. Always also grep the startup log
for `Unknown key` and confirm the live policy with `showPoolServerPolicy("")`.

## CI: which workflow deploys DNS

`infrastructure-deploy.yml` deploys pihole and dnsdist (via terraform).
`services-deploy.yml` explicitly **excludes** them with negated path patterns,
because they are not in `services/infrastructure-test.yml` or the services
inventory and it would only ever produce a no-op run.

Gitea supports negated `paths` (1.19.1+, GitHub semantics, last match wins). Do
not assume this if it is ever changed: unsupported negation makes
`CompilePatterns` error and the workflow **silently stops triggering entirely**.

`services-deploy.yml`'s role-detection whitelist must stay in sync with the
imports in `services/infrastructure-test.yml`. It drifted once -- fission,
microk8s and nats deployed in full runs but a change confined to one of them
matched nothing and the run went green having deployed nothing.

## Known open posture gaps (not yet addressed)

- Clients -> dnsdist is still plaintext :53 on the LAN. eero cannot hand out
  DoT/DoH, so this would require per-client configuration.
- `infrastructure/ups-monitoring/main.tf` uses
  `filesha256("${path.module}/../../../...")`, which climbs above the repo root;
  that stack cannot `validate`, let alone apply. It is not in `deploy.sh`, so
  nothing auto-deploys it.
- `infrastructure/ups-monitoring/main.tf` uses `filesha256("${path.module}/../../../...")`
  which climbs above the repo root — that stack cannot `validate`, let alone apply.
- `services/dnsdist/**` and `services/pihole/**` match the path filters of *both*
  gitea workflows, so every DNS change produces two runs, one meaningful.
