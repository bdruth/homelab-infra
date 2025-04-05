# Homelab Infrastructure Guide

## Build & Deploy Commands
- Deploy DNS infrastructure: `./deploy.sh` or `./nix-deploy.sh` or `./pkgx-deploy.sh`
- Run Ansible Pihole test: `cd ansible/pihole && ansible-playbook -i test-inventory.yml test-playbook.yml`

## Terraform/OpenTofu
- Apply changes: `cd dns/[component] && terraform apply`
- Plan changes: `cd dns/[component] && terraform plan`
- Validate: `cd dns/[component] && terraform validate`

## Ansible
- Run playbook: `ansible-playbook -i [inventory] [playbook].yml`
- Check syntax: `ansible-playbook --syntax-check [playbook].yml`
- Dry run: `ansible-playbook -i [inventory] [playbook].yml --check`

## Code Style Guidelines
- Follow infrastructure-as-code best practices
- Use descriptive variable names
- Include comments for complex configurations
- Maintain consistent indentation in YAML files (2 spaces)
- Document all environment-specific configurations
- Use blue/green deployment strategy for critical services
- Keep components modular with clear separation of concerns