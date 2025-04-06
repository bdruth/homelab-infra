# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Deploy Commands
- Deploy DNS infrastructure: `./deploy.sh` or `./nix-deploy.sh` or `./pkgx-deploy.sh`
- Run Ansible playbook: `ansible-playbook -i [inventory] [playbook].yml`
- Run NVIDIA GPU test: `cd ansible/nvidia-gpu && ansible-playbook -i test-inventory.yml test-playbook.yml`
- Run Pihole test: `cd ansible/pihole && ansible-playbook -i test-inventory.yml test-playbook.yml`
- Verify installation: `nvidia-smi`, `nvcc --version`, `ollama --version`, `btop --version`, `uv --version`

## Terraform/OpenTofu
- Apply changes: `cd dns/[component] && terraform apply`
- Plan changes: `cd dns/[component] && terraform plan`
- Validate: `cd dns/[component] && terraform validate`

## Ansible
- Run playbook: `ansible-playbook -i [inventory] [playbook].yml`
- Check syntax: `ansible-playbook --syntax-check [playbook].yml`
- Dry run: `ansible-playbook -i [inventory] [playbook].yml --check`

## Container Management
- We use podman with podman-docker compatibility layer
- Always use Docker CLI commands (not podman commands) for consistency
- Examples: `docker ps`, `docker compose up -d`, `docker build`
- The underlying implementation uses podman but we use docker CLI syntax

## Code Style Guidelines
- Follow infrastructure-as-code best practices
- Use descriptive variable names (e.g., `nvidia_driver_version`, `install_btop`)
- Use consistent feature toggles with boolean variables
- Include task comments describing purpose
- Maintain consistent indentation in YAML files (2 spaces)
- Handle errors with retries and proper ignore_errors handling
- Organize tasks into modular files with clear responsibilities
- Use templates (.j2 files) for configuration generation
- Register command outputs for validation and debugging