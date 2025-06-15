# Services Directory

This directory contains service configurations and deployment playbooks for the homelab infrastructure.

## Structure

- Individual service directories containing role definitions
- `*-only.yml` files for standalone service deployments
- `infrastructure.yml` for combined infrastructure deployment
- Configuration files and templates for each service

## Usage

Services can be deployed individually or as part of the complete infrastructure using the deployment scripts:

```bash
./services-deploy.sh services/{service-name}-only.yml  # Deploy single service
./services-deploy.sh services/infrastructure.yml       # Deploy full infrastructure
```

## Available Services

- DNS management (Pi-hole, DNSDist)
- Git services (Gitea, Gitea Act Runner)
- CI/CD (Drone CI, Drone Runners)
- Monitoring (UPS monitoring, disk monitoring)
- Utilities (Watchtower)
- GPU services (NVIDIA GPU configuration)
