# AgentsView pilot on Synology

This role adopts the existing `agentsview-pilot` Compose project on `synology1`.
It does not bootstrap or import an archive. The native transcript sources,
SQLite database, offloaded images, token, and application configuration remain
under `/volume1/docker/compose/agentsview-pilot/` on the NAS.

## Access design

- Browser URL: `https://agentsview.cusack-ruth.name/` on the LAN or tailnet.
- Internal Pi-hole CNAME: `agentsview.cusack-ruth.name` → `beelink.cusack-ruth.name`.
  No public Cloudflare DNS record is managed for this service.
- TLS: existing nginx on beelink and its `*.cusack-ruth.name` certbot certificate.
- nginx permits LAN and tailnet clients; the existing Authelia rule applies
  (LAN bypass, two-factor elsewhere). AgentsView independently requires its
  bearer token for every `/api/` request.
- nginx connects to NAS management IP `192.168.7.211:18080`. A NAS
  `INPUT` rule drops traffic to that published port unless the source is the
  beelink proxy at `192.168.7.198`; a `DOCKER-USER` rule covers forwarded
  packets. The former NAS loopback publication was removed after HTTPS
  validation. The handoff's Mac LaunchAgent was absent on this workstation;
  no loaded tunnel needed removal.
- The site is rooted at `/`; nginx forwards Host and HTTPS scheme, disables
  buffering, and allows one-hour stream reads. AgentsView `public_url` trusts
  the browser origin; no extra proxy stack or public ingress is installed.

## Managed files and convergence

- `services/agentsview/files/compose.yaml` preserves the pinned `0.46.1`
  image, `1026:100` runtime user, 4 GiB memory limit, 6 GiB memory plus swap,
  `cpu_shares: 256`, restart policy, and existing relative mounts.
- `services/agentsview/tasks/main.yml` checks that the pilot and ownership
  exist before copying Compose and setting `public_url` in the existing
  `data/config.toml`. It never writes the token or source configuration.
- `services/agentsview/files/agentsview-proxy-firewall.sh` installs the NAS
  Docker forwarding restriction and is also installed as a Synology boot hook.
  Its effect after a full NAS reboot still needs a maintenance-window check;
  the current live INPUT and DOCKER-USER rules were verified directly.
- `services/authelia-proxy/files/nginx/conf.d/agentsview.cusack-ruth.name.conf`
  is the new site in the existing proxy.
- `services/pihole/vars/main.yml` lists the internal CNAME. The normal
  `services/pihole/main.yml` playbook renders a Pi-hole FTL v6.8 template and
  compares parsed TOML values before replacing live configuration. The
  `pihole-config` tag applies just this configuration through the same tasks.
- The proxy role's Grafana site and Compose template were reconciled to the
  live stack before this route was added. `services/authelia-proxy-only.yml`
  runs the complete existing proxy role without unrelated host roles.

The role is wired into `services/infrastructure.yml` for inventory ownership
but is deliberately omitted from CI convergence, like the proxy role. DNS
remains under the normal infrastructure deployment workflow.

## Validation and operations

After applying, check DNS from the intended client network and the wildcard
certificate on `https://agentsview.cusack-ruth.name/`. Verify the HTML and a
referenced static asset, `/api/ping` with and without the bearer token,
`/api/v1/sync/status`, sessions, transcript retrieval, full-text search, and
the `/api/v1/events` stream. The token stays on the NAS at
`secrets/token`; never put it into a URL, repository file, or logs. A healthy
pilot has `startup_pending=false`, `archive_stale=false`, and no import
failures. The search example is
`/api/v1/search/content?pattern=docker&mode=fts&limit=10`.

On 2026-10-31, both Pi-hole nodes and this Mac resolved the CNAME; IPv4 and
IPv6 HTTPS validated the wildcard certificate. The HTML and a JavaScript
asset returned 200, `/api/ping` returned 401 without and 200 with a token,
and authenticated sync, sessions, transcript messages, full-text search, and
SSE `events_ready` checks passed. Sync status reported
`startup_pending=false`, `archive_stale=false`, and `failed=0`. A direct Mac
connection to the NAS upstream timed out while beelink reached it; NAS SSH
and Gitea remained available.

The imported pilot is 567 native JSONL files, roughly 7.8 GiB. It includes
fork ancestors, but it is not the full roughly 53 GiB transcript collection.
No full-history sync, source deletion, PostgreSQL, embeddings, or external
model endpoint is managed here. Keep `./data` owned by UID 1026/GID 100;
the daemon needs that ownership. The old Mac SSH tunnel is no longer part of
the managed access path.
