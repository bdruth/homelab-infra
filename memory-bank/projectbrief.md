# Project Brief: Homelab Infrastructure

## Overview

This project manages a comprehensive homelab infrastructure using Infrastructure as Code (IaC) principles. It provides automated deployment and configuration of various services across a home network environment.

## Core Goals

- Maintain consistent, repeatable deployments using Ansible and Terraform/OpenTofu
- Provide high availability for critical services
- Enable CI/CD workflows within the homelab
- Monitor system health and resources
- Document and track infrastructure changes

## Key Components

1. **Self-hosted Services**:

   - Gitea (Git service)
   - Drone CI
   - Pi-hole (DNS ad blocking)
   - Various monitoring tools

2. **Infrastructure Management**:

   - Ansible playbooks for service deployment and configuration
   - Terraform/OpenTofu for DNS and infrastructure provisioning
   - Deployment scripts for various environments

3. **Monitoring Solutions**:

   - UPS monitoring
   - Disk monitoring with Grafana dashboards
   - System health checks

4. **CI/CD Pipeline**:
   - Drone runners for CI/CD workflows
   - Gitea Act runners for GitHub Actions compatibility

## Target Environment

- Mixed environment of physical and virtual servers
- Network services for home lab use
- Potential integration with cloud services for specific functions

## Success Metrics

- Reliable, automated deployments
- Minimal manual intervention required for maintenance
- Comprehensive monitoring and alerting
- Well-documented infrastructure for future reference
- Easy recovery in case of system failure

## Scope Boundaries

- Focuses on homelab infrastructure services
- Does not include application development unrelated to infrastructure
- Prioritizes automation and infrastructure stability
