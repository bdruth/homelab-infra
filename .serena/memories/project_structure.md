# Project Structure

## Main Directories

- `/` - Root directory containing global configuration and deployment scripts
- `/infrastructure/` - Infrastructure as Code (Terraform/OpenTofu) resources
  - `/infrastructure/dns/` - DNS-related infrastructure (Pi-hole, dnsdist)
  - `/infrastructure/modules/` - Reusable Terraform/OpenTofu modules
  - `/infrastructure/ups-monitoring/` - UPS monitoring infrastructure
- `/services/` - Ansible playbooks and roles for service configuration
  - Individual service directories containing role definitions
  - Service-specific configuration files and templates

## Key Files

### Root Directory

- `deploy.sh` - Main infrastructure deployment script
- `pkgx-deploy.sh` - Wrapper script using pkgx to manage dependencies for deploy.sh
- `services-deploy.sh` - Main services deployment script
- `services-pkgx-deploy.sh` - Wrapper script using pkgx for services-deploy.sh
- `setup-ansible.sh` - Script to set up Ansible environment
- `.pre-commit-config.yaml` - pre-commit hook configuration
- `.ansible-lint.yml` - Ansible linter configuration
- `.megalinter.yml` - MegaLinter configuration

### Infrastructure Directory

Typical Terraform/OpenTofu project structure:
- `main.tf` - Main resource definitions
- `variables.tf` - Input variable declarations
- `outputs.tf` - Output value declarations
- `providers.tf` - Provider configuration
- `*.tfvars` - Variable values (often with .example variants)
- `*.tfbackend` - Backend configuration (often with .example variants)

### Services Directory

- `inventory.yml` - Ansible inventory file (with example variant)
- `*.yml` - Playbooks for various services
- Service directories follow Ansible role structure:
  - `defaults/` - Default variables
  - `tasks/` - Task definitions
  - `templates/` - Jinja2 templates
  - `vars/` - Variable definitions
  - `handlers/` - Handler definitions
  - `meta/` - Role metadata