# Tailscale Role

## Overview

This role installs and configures Tailscale for remote administration of a host, using the community role `artis3n.tailscale.machine` (declared in `requirements.yml`). It is a thin standalone wrapper: any host tagged with `tailscale` in `host_roles` can include this role to join the tailnet.

This is distinct from the Tailscale usage already embedded in the `dnsdist` role. dnsdist runs on LXC containers without TUN device access, so its copy additionally configures `/etc/default/tailscaled` for userspace networking. This role targets real hosts with a real TUN device, so no such override is needed here.

## Requirements

- `artis3n.tailscale` collection (`>=1.2.0`, already declared in `requirements.yml`)
- A host with a real TUN device (this role does not configure userspace networking)

## Role Variables

### Required Variables

| Variable            | Default | Description                                                                 |
| ------------------- | ------- | ---------------------------------------------------------------------------|
| `tailscale_authkey`  | none    | Tailscale auth key. Must be supplied via inventory/host_vars for the host using this role -- it is a secret and is never set as a default. |

### Optional Variables

`tailscale_args` is fixed by this role to `--accept-dns=false`, since Tailscale here is only for remote administration and must not take over DNS resolution on the host.

## Example

```yaml
# In host_vars or group_vars for the host using this role
tailscale_authkey: "tskey-auth-..."
```

```yaml
- name: Install Tailscale
  ansible.builtin.include_role:
    name: tailscale
  when: "'tailscale' in host_roles"
```

## Testing

```bash
./services-pkgx-deploy.sh tailscale/test-playbook.yml
```

The test playbook dynamically groups hosts whose `host_roles` includes `tailscale`, then asserts that `tailscaled.service` is active.

## License

MIT
