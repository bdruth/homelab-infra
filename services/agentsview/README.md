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

The role is wired into `services/infrastructure.yml`. CI converges it
through `services/agentsview/test-playbook.yml`, which runs
`agentsview-only.yml` against `inventory.yml` only. That covers the NAS and
the Linux uploaders, while the Macs stay manual. A CI run that changes the
rendered `config.toml` restarts AgentsView. The proxy role remains manual.
DNS remains under the normal infrastructure deployment workflow.

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

The original pilot was 567 native JSONL files, roughly 7.8 GiB, from
flexion-mac. The transcript uploaders below replace it with full history.
No source deletion, PostgreSQL, embeddings, or external model endpoint is
managed here. Keep `./data` owned by UID 1026/GID 100;
the daemon needs that ownership. The old Mac SSH tunnel is no longer part of
the managed access path.

## Transcript uploaders

Every host in the `agentsview_uploaders` group pushes its native Claude
(`~/.claude/projects`) and Codex (`~/.codex/sessions`) JSONL files to the NAS
every 15 minutes. The Linux hosts (beelink, beelink-gti, ubuntu-22) are in
`inventory.yml`. The Macs (brice-mbp-m1max, flexion-mac) are in
`agentsview/workstations.yml`, which is kept separate so that `hosts: all`
plays never target them. asrock-nuc and weewx-pi4 had no session history on
2026-10-31 and are not uploaders.

Apply everything with:

    ansible-playbook -i inventory.yml -i agentsview/workstations.yml agentsview-only.yml

The playbook creates each uploader's key, then configures the NAS, then
installs the uploader. How it works:

- Each uploader has its own key, `~/.ssh/agentsview_upload`, and pins the
  NAS host key in `~/.ssh/agentsview_known_hosts`. The pinned key is read
  from the NAS itself, not trusted on first use.
- On the NAS, each key's `authorized_keys` entry is `restrict` and forced
  through `bin/agentsview-upload-guard <dir>`. The guard allows only a
  receiving rsync with a fixed set of options into `sources/<dir>/claude/projects`
  or `sources/<dir>/codex/sessions`. It rejects reads, `--delete`, and
  every other option.
- `~/.local/bin/agentsview-upload` runs rsync with no `--delete`, so
  sessions that Claude or Codex later remove locally stay in the archive.
  Whole trees are sent, so fork and subagent parents arrive with their
  children. It makes three passes:
  - Claude, with `--append-verify`: `*.jsonl` transcripts and the
    write-once files beside them: `tool-results/**` (large tool outputs
    that the transcript holds only as a preview and a path) and
    `subagents/**/*.meta.json`.
  - Claude project `memory/*.md`, without `--append`, because those files
    are rewritten in place.
  - Claude `file-history/` (the checkpoints behind `/rewind`), with
    `--append-verify`.
  - Codex, with `--append-verify`: `*.jsonl` only.

  AgentsView indexes only the transcripts. The other files are kept on the
  NAS so the raw archive is complete.
- The schedule is LaunchAgent `name.cusack-ruth.agentsview-upload` on
  macOS (log: `~/Library/Logs/agentsview-upload.log`) and
  `agentsview-upload.timer` under systemd on Linux (log:
  `journalctl -u agentsview-upload`).
- `data/config.toml` holds a managed `session_sources` block with one
  folder and machine key per host from `agentsview_upload_sources` in
  `vars/main.yml`. flexion-mac keeps the pilot folder `sources/mac` and
  machine key `316226fb…`. A session keeps the machine key from its first
  import, so never change an existing key.
- The uploaders reach the NAS at its LAN address. A Mac away from home
  logs connection failures and catches up when it is back on the LAN.

To add a host, add it to `agentsview_uploaders` and to
`agentsview_upload_sources`, then rerun the playbook.

On 2026-10-31, the pilot `mac` `session_sources` entries were moved into
the managed block and `cursor_secret` was rotated. The earlier file is
`data/config.toml.pre-uploaders-20261031` on the NAS.

## Resuming an archived session

`~/.local/bin/agentsview-rehydrate` on every uploader restores a session
from the raw archive so Claude or Codex can resume it:

```bash
agentsview-rehydrate <session id, codex:<id>, or an AgentsView URL>
agentsview-rehydrate <id> --print       # restore, print the resume command
agentsview-rehydrate <id> --cwd ~/src/x # original directory missing here
agentsview-rehydrate <id> --at 234      # branch at AgentsView message 234
agentsview-rehydrate "<a message's Resume command>"  # same, pasted
agentsview-rehydrate "https://agentsview.cusack-ruth.name/...?msg=234"
```

- It restores from the raw files, not from AgentsView's database, so the
  transcript is byte for byte what the original wrote. For Claude it also
  restores the session's `tool-results`, subagent transcripts and
  `file-history`.
- It never overwrites local files. An identical or longer local transcript
  is kept; one that differs from the archive stops the restore.
- A session from another machine is forked by default
  (`claude --resume <id> --fork-session`, `codex fork <id>`), after a
  warning and, at a terminal, a prompt. Resuming it in place would write
  the same session id from two machines. The restored original is listed
  in `~/.local/state/agentsview/upload-exclude/` so the uploader does not
  send it again under this host.
- It reads the archive with its own key, `~/.ssh/agentsview_read`, forced
  through `bin/agentsview-read-guard` on the NAS. That guard allows only a
  session lookup and rsync reads under `sources/`, so the read key cannot
  write and the upload key cannot read.
- `--at ORDINAL` (Claude only) branches at an AgentsView message instead
  of the session's end. The ordinal comes from AgentsView: a message's
  **Resume session** action copies a command naming `<id>-ordinal-<n>`, and a
  link to a message ends in `?msg=<n>`. Pasting either works without `--at`. AgentsView's own message-point command pastes a
  text rendering into a new session. This cuts the raw transcript at that
  message instead and saves the prefix under a new session id, with copies
  of the subagents, tool results and `/rewind` checkpoints. The branch
  holds exactly what Claude had at that moment. That matters most across
  compactions: Claude's own resume and fork always start from the latest
  compacted state, while a branch from before a compaction has the full,
  uncompacted context. At a user message the cut falls just before it and
  the prompt is sent again; at an assistant message the cut falls at the
  end of that turn. The branch is a new session on this machine, so it
  uploads like any other.
- What a resume cannot bring back: the machine state the session ran
  against (working tree, git state, MCP servers, permissions), Codex
  `generated_images/`, and tool-result paths that point into another
  machine's home directory.

