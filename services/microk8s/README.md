# MicroK8s Role

This Ansible role installs and configures MicroK8s, a lightweight Kubernetes distribution, for single-node deployments.

## Features

- Single-node MicroK8s installation via snap
- Basic add-on management (DNS, hostpath-storage)
- User group management for seamless kubectl access
- Syslog forwarding to centralized logging server
- IPv4/IPv6 network support
- Automatic service management

## Requirements

- Ubuntu 20.04+ (or any snapd-compatible Linux distribution)
- Minimum 4GB RAM
- Minimum 20GB disk space
- snapd installed and configured

## Role Variables

### Main Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `install_microk8s` | `false` | Enable MicroK8s installation |
| `microk8s_channel` | `"1.32/stable"` | Snap channel for MicroK8s version |
| `microk8s_kubectl_alias` | `true` | Create kubectl alias for convenience |
| `microk8s_auto_start` | `true` | Auto-start MicroK8s after reboot |

### Add-ons Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `microk8s_addons_enabled` | `["dns", "hostpath-storage"]` | List of add-ons to enable |

### Logging Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `microk8s_syslog_enabled` | `true` | Enable syslog forwarding |
| `microk8s_syslog_server` | `"graylog.cusack-ruth.name"` | Syslog server hostname |
| `microk8s_syslog_port` | `514` | Syslog server port |
| `microk8s_syslog_protocol` | `"udp"` | Syslog protocol |

### Network Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `microk8s_enable_ipv6` | `auto-detected` | Enable IPv6 support (auto-detected from host) |

## Dependencies

None

## Example Inventory Configuration

```yaml
k8s-server.example.com:
  ansible_host: 192.168.1.104
  host_roles: [microk8s]
  # MicroK8s configuration
  install_microk8s: true
  microk8s_addons_enabled:
    - dns
    - hostpath-storage
    - dashboard
    - ingress
```

## Example Playbook

### Standalone Deployment

```bash
# Deploy only to hosts with microk8s role
ansible-playbook -i inventory.yml microk8s/main.yml
```

### Integrated Deployment

```bash
# Deploy as part of full infrastructure
ansible-playbook -i inventory.yml infrastructure.yml
```

## Available Add-ons

Common MicroK8s add-ons that can be enabled:

- `dns` - DNS resolution within the cluster
- `hostpath-storage` - Local storage provisioner
- `dashboard` - Kubernetes web dashboard
- `ingress` - Ingress controller for external access
- `metrics-server` - Resource metrics API
- `registry` - Private container registry
- `storage` - Storage provisioner

## Post-Installation

After successful installation, you can:

1. **Check cluster status:**
   ```bash
   microk8s status
   ```

2. **Access kubectl:**
   ```bash
   microk8s kubectl get nodes
   # or if alias is enabled:
   kubectl get nodes
   ```

3. **View enabled add-ons:**
   ```bash
   microk8s status --format yaml
   ```

4. **Deploy test workload:**
   ```bash
   microk8s kubectl create deployment nginx --image=nginx
   microk8s kubectl get pods
   ```

## Testing

The role includes comprehensive testing tasks:

```bash
# Run tests
ansible-playbook -i inventory.yml microk8s/test-playbook.yml
```

## Logging

MicroK8s logs are automatically forwarded to the configured syslog server, including:

- MicroK8s service logs
- Kubernetes component logs (kubelet, containerd)
- Snap service logs

## Troubleshooting

### Common Issues

1. **Installation fails:** Ensure snapd is installed and working
2. **Permission denied:** User needs to re-login after group addition
3. **Add-on failures:** Check system resources and network connectivity
4. **Syslog not forwarding:** Verify rsyslog service is running

### Debug Commands

```bash
# Check snap services
snap services microk8s

# View MicroK8s logs
journalctl -u snap.microk8s.daemon-apiserver

# Check system resources
free -h
df -h
```

## License

MIT

## Author Information

Created for homelab-infra project.
