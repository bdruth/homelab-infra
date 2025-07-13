# Fission Ansible Role

This role deploys the Fission serverless framework on a MicroK8s Kubernetes cluster using Helm.

## Overview

Fission is a serverless framework for Kubernetes that allows you to run functions without managing the underlying infrastructure. This role handles the complete installation including prerequisites, CRDs, and the Helm chart deployment.

## Prerequisites

- MicroK8s cluster running
- Ansible with `kubernetes.core` collection
- Helm 3.x

## Role Tasks

1. **Storage Setup**: Enables MicroK8s hostpath-storage addon
2. **Helm Repository**: Adds the official Fission Helm repository  
3. **CRD Installation**: Installs all Fission CRDs using server-side apply workaround
4. **Namespace Creation**: Creates the Fission namespace
5. **Helm Deployment**: Deploys Fission using the official Helm chart
6. **CLI Installation**: Downloads and installs the Fission CLI (optional)

## Configuration

Key variables in `defaults/main.yml`:

```yaml
# Fission deployment settings
fission_namespace: fission
release_name: fission
chart_repo_name: fission-charts
chart_repo_url: https://fission.github.io/fission-charts/
chart_name: fission-all

# CLI installation
fission_cli_install: true
fission_cli_version: ""  # Empty string uses latest

# Example: Fission chart values with NATS message queue support
fission_chart_values:
  messagequeue:
    nats:
      enabled: true
      url: "nats://nats.nats-system.svc.cluster.local:4222"
```

## Important Notes

### CRD Installation Workaround

This role uses a special workaround for Fission CRD installation due to annotation size limits:

- Fission CRDs contain large annotations (>262KB) that exceed Kubernetes limits
- We use server-side apply with `kubernetes.core.k8s` to bypass this limitation
- All official Fission CRDs are installed individually for reliability

### MicroK8s Compatibility

- Uses `microk8s` commands where needed for snap environment compatibility
- Automatically enables required addons (hostpath-storage)
- Handles kubeconfig export for Ansible Kubernetes modules

## Testing

Run the test playbook to verify installation:

```bash
ansible-playbook test-playbook.yml -i test-inventory.yml
```

Tests verify:
- All Fission pods are running
- CLI installation and version
- Basic functionality with `fission check`

## NATS Integration

To enable NATS message queue integration with Fission:

1. Deploy NATS first using the NATS role
2. Configure Fission chart values for NATS message queue:

```yaml
fission_chart_values:
  messagequeue:
    nats:
      enabled: true
      url: "nats://nats.nats-system.svc.cluster.local:4222"
```

This configures Fission to use NATS for message queue triggers, enabling event-driven serverless functions.

## Usage Example

### Basic Installation
```yaml
- name: Install Fission
  include_role:
    name: fission
  vars:
    fission_cli_install: true
```

### With NATS Integration
```yaml
# In inventory or group_vars
fission_chart_values:
  messagequeue:
    nats:
      enabled: true
      url: "nats://nats.nats-system.svc.cluster.local:4222"

# In playbook
- name: Install NATS messaging
  include_role:
    name: nats

- name: Install Fission with NATS support
  include_role:
    name: fission
```

## References

- [Fission Documentation](https://fission.io/docs/)
- [Official Installation Guide](https://fission.io/docs/installation/)
- [Helm Chart Repository](https://github.com/fission/fission-charts)
