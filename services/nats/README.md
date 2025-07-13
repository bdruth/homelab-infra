# NATS Messaging System Role

## Overview

This Ansible role deploys NATS, a lightweight and high-performance messaging system, on MicroK8s using the official NATS Helm chart. NATS provides messaging capabilities including pub/sub, request/reply, and JetStream for persistence.

## Features

- **High Performance**: Lightweight messaging with low latency
- **JetStream Support**: Optional persistent streaming and storage
- **Kubernetes Native**: Deployed using official NATS Helm charts
- **Scalable**: Configurable resource limits and clustering support
- **Integration Ready**: Compatible with Fission serverless framework

## Requirements

- MicroK8s cluster with Helm addon enabled
- Kubernetes access configured for Ansible
- `kubernetes.core` Ansible collection

## Role Variables

### Required Variables

None. All variables have sensible defaults.

### Optional Variables

```yaml
# Helm chart configuration
chart_repo_name: nats                                    # Helm repository name
chart_repo_url: https://nats-io.github.io/k8s/helm/charts/  # NATS Helm repository URL
chart_name: nats                                         # Chart name
chart_version: ""                                        # Chart version (empty = latest)
release_name: nats                                       # Helm release name
nats_namespace: nats-system                              # Kubernetes namespace

# NATS configuration
nats_chart_values:
  nats:
    jetstream:
      enabled: true                                      # Enable JetStream for persistence
      fileStore:
        pvc:
          size: 10Gi                                     # Storage size for JetStream
    resources:
      requests:
        cpu: 100m                                        # CPU request
        memory: 128Mi                                    # Memory request
      limits:
        cpu: 500m                                        # CPU limit
        memory: 512Mi                                    # Memory limit
  monitoring:
    enabled: false                                       # Enable monitoring endpoints
  service:
    type: ClusterIP                                      # Service type
    ports:
      nats: 4222                                         # NATS client port
      monitoring: 8222                                   # Monitoring port
      jetstream: 9222                                    # JetStream port
```

## Example Playbook

```yaml
---
- name: Deploy NATS messaging system
  hosts: microk8s_primary
  become: true
  vars:
    # Enable monitoring
    nats_chart_values:
      monitoring:
        enabled: true
      nats:
        jetstream:
          enabled: true
          fileStore:
            pvc:
              size: 20Gi
  roles:
    - role: nats
```

## Usage

### Deploy NATS

```bash
# Deploy NATS standalone
./services-pkgx-deploy.sh nats/main.yml

# Test NATS deployment
./services-pkgx-deploy.sh nats/test-playbook.yml
```

### Integration with Fission

To enable NATS integration with Fission:

```yaml
# In inventory or group_vars
enable_nats_integration: true
nats_url: "nats://nats.nats-system.svc.cluster.local:4222"
```

### NATS Connection Details

After deployment, NATS is accessible at:
- **Internal URL**: `nats://nats.nats-system.svc.cluster.local:4222`
- **Monitoring**: `http://nats.nats-system.svc.cluster.local:8222` (if enabled)
- **JetStream**: `nats://nats.nats-system.svc.cluster.local:9222`

## Dependencies

- `microk8s` role (automatically included)
- MicroK8s Helm addon

## Testing

The role includes comprehensive testing:

- Verifies NATS deployment readiness
- Checks service availability
- Validates JetStream StatefulSet (if enabled)
- Reports pod status and connection details

## Architecture

```text
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Fission       │    │      NATS       │    │   Applications  │
│   Functions     │◄──►│   Messaging     │◄──►│   & Services    │
│                 │    │   (Port 4222)   │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                    ┌─────────────────┐
                    │   JetStream     │
                    │   Persistence   │
                    │   (Port 9222)   │
                    └─────────────────┘
```

## Security Considerations

- NATS runs within Kubernetes cluster networking
- ClusterIP service type provides internal access only
- JetStream data is persisted in PVCs
- No external exposure by default (configure ingress if needed)

## Troubleshooting

### Check NATS pods
```bash
kubectl get pods -n nats-system
```

### View NATS logs
```bash
kubectl logs -n nats-system deployment/nats
```

### Test NATS connectivity
```bash
kubectl run nats-test --rm -it --image=natsio/nats-box:latest -- /bin/sh
# Inside the pod:
nats pub test "hello world" --server=nats://nats.nats-system.svc.cluster.local:4222
```

## License

MIT
