# Node-RED Ansible Role

Deploys [Node-RED](https://nodered.org/) as a podman container on a target host,
managed by a systemd service unit.

## Architecture

- Runtime: podman (via docker shim)
- Networking: `network_mode: host` (required for mDNS/Avahi on UDP 5353)
- Data: bind-mount of `<nodered_install_dir>` into `/data` inside the container
- Avahi/D-Bus: socket pass-throughs for IoT device discovery
- Compose file: standalone at `<nodered_compose_dir>/docker-compose.yml`
- Systemd unit: `/etc/systemd/system/nodered.service`

## Role Variables

### `defaults/main.yml`

| Variable | Default | Description |
|---|---|---|
| `install_nodered` | `false` | Master toggle — set `true` in inventory to provision |
| `nodered_install_dir` | `/opt/nodered` | Host-side workdir (bind-mounted as `/data`) |
| `nodered_compose_dir` | `/etc/docker/compose/nodered` | Directory for the compose file |
| `nodered_image` | `docker.io/nodered/node-red:latest` | Container image |
| `nodered_user` | `node-red` | System user owning the workdir |
| `nodered_uid` | `1000` | UID for the node-red user |
| `nodered_group` | `node-red` | System group |
| `nodered_gid` | `1000` | GID for the node-red group |
| `nodered_port` | `1880` | HTTP port for the editor and API |
| `nodered_safe_mode` | `false` | When `true`, injects `NODE_RED_SAFE_MODE=1` so flows load but do not execute |
| `nodered_restart_policy` | `unless-stopped` | Container restart policy |

### `vars/main.yml` (git-crypt encrypted)

| Variable | Description |
|---|---|
| `nodered_credential_secret` | AES-256 key that encrypts `flows_cred.json` — must be preserved identically |
| `nodered_flows_cred_json` | Base64-encoded content of `flows_cred.json` |
| `nodered_admin_password_hash` | Bcrypt hash for the Node-RED editor admin user |

These are placeholders in the committed file. Fill them in after `git-crypt unlock`.

## Safe-Mode Toggle

`nodered_safe_mode: true` injects `NODE_RED_SAFE_MODE=1` into the container
environment. Flows are loaded and parsed (validates `flows.json`, credentials,
and node modules), but nothing executes — MQTT subscriptions, scheduled nodes,
Kasa polling, and homebridge events are all suppressed.

This is the required strategy for Phase 3 parallel staging: the new host runs
in safe mode until Phase 6 cutover, at which point:

1. Stop the parallel instance.
2. Set `nodered_safe_mode: false` in inventory.
3. Run the role again (triggers a container restart).
4. Smoke-test the editor endpoint.
5. Perform the DNS/nginx upstream swap.

## Ports

| Port | Protocol | Purpose |
|---|---|---|
| 1880 | TCP | Node-RED editor and HTTP API |
| 5353 | UDP | mDNS (Avahi — IoT device discovery via host networking) |

## Running Standalone

```bash
# Syntax check
ansible-playbook --syntax-check \
  -i services/nodered/test-inventory.yml \
  services/nodered/main.yml

# Dry-run against target host (orchestrator-gated)
ansible-playbook --check --diff \
  -i services/nodered/test-inventory.yml \
  services/nodered/main.yml

# Apply
ansible-playbook \
  -i services/nodered/test-inventory.yml \
  services/nodered/main.yml
```

## Dependencies

The role assumes the target host already has:

- `podman` and `podman-docker` (docker CLI shim)
- `avahi-daemon` running with its socket at `/var/run/avahi-daemon/socket`
- `dbus` running with its socket directory at `/var/run/dbus`

The role does **not** install these dependencies — they are provisioned by
earlier plays or by the host's base image.

## Inventory Example

```yaml
all:
  hosts:
    nodered-host.example.com:
      ansible_host: 192.0.2.10
      host_roles:
        - nodered
      install_nodered: true
      # Override for Phase 3 parallel staging:
      nodered_safe_mode: true
```
