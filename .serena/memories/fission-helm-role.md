# Fission Ansible Role

## Overview
Ansible role `fission` deploys Fission serverless framework on MicroK8s using Helm chart `fission-charts/fission-all`.

## Key Features
- **CRD Installation**: Uses official Fission CRDs with server-side apply workaround for annotation size limits
- **Storage Setup**: Automatically enables MicroK8s hostpath-storage addon
- **Helm Integration**: Deploys Fission via official Helm chart
- **CLI Installation**: Downloads and installs Fission CLI binary
- **Testing**: Includes comprehensive test tasks with version verification

## Architecture
- **Prerequisites**: Handles MicroK8s storage, Helm repo, and CRDs
- **Deployment**: Uses `kubernetes.core.helm` module for idempotent installations
- **Configuration**: Configurable via defaults with version pinning support
- **Integration**: Fully integrated into infrastructure playbooks

## Important Notes
- Requires manual CRD installation before Helm chart (per Fission docs)
- Uses server-side apply to handle large CRD annotations
- Compatible with MicroK8s snap environment
- Follows project standards for role structure and testing
