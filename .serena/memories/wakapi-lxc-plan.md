Wakapi deployment plan (homelab-infra)

Architecture
- Run Wakapi as a native Go binary inside an unprivileged Debian 12 LXC (no Docker/Compose in LXC).
- Manage Wakapi via systemd; configuration via env file.
- Default to SQLite with data under /opt/wakapi/data; consider Postgres only if needed later.

Proxmox/LXC
- Use existing Terraform module infrastructure/modules/lxc.
- Container features: nesting=true, unprivileged=true, onboot=true.
- Networking: static IP via module vars; gateway from gw_addr.
- Persistence: plan an LXC mountpoint mp0 -> /opt/wakapi; prefer storage-backed mount with backup=true (bind-mount allowed with proper UID/GID mapping). Add mount after initial LXC verification.

Infrastructure repo integration
- New stack at infrastructure/wakapi/ mirroring providers/backend pattern from infrastructure/ups-monitoring/providers.tf (telmate/proxmox v3.0.1-rc8, S3 backend path-style, AWS endpoint).
- Minimal first pass: create LXC only (module call + output); wire Ansible later.

Ansible role (later step)
- services/wakapi/: defaults, tasks (install binary, create /opt/wakapi, env file, systemd unit), handlers, templates (service + env), README, and a minimal test playbook.

Incremental steps (YAGNI)
1) Terraform: create LXC stack (no mounts yet), provision container.
2) Ansible: minimal role to install and run Wakapi; verify service.
3) Add LXC mountpoint for /opt/wakapi and migrate data if needed.
4) Optional: reverse proxy/DNS/TLS wiring.
