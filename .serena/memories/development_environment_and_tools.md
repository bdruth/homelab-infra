# Development Environment and Tools

## Required Tools

- **Ansible**: For running playbooks and roles
- **Terraform/OpenTofu**: For managing DNS infrastructure
- **Git**: For version control and interaction with Gitea
- **Docker**: For container management
- **pkgx**: Alternative package manager used in some deployment scripts
- **pre-commit**: Git hooks management for code quality
- **git-crypt**: Secrets management in repository

## Deployment Patterns and Commands

### Standard Deployment Commands

```bash
# Deploy services with Ansible
./services-deploy.sh services/{service-name}-only.yml  # Deploy single service
./services-deploy.sh services/infrastructure.yml       # Deploy full infrastructure

# Deploy with pkgx dependency management
./services-pkgx-deploy.sh                              # Default deployment
./services-pkgx-deploy.sh {service-name}-only          # Specific service
./services-pkgx-deploy.sh --playbook=services/specific-playbook.yml --inventory=services/custom-inventory.yml  # Custom options

# Infrastructure deployment
./pkgx-deploy.sh                                       # Full infrastructure
./infra-deploy.sh dns-ha plan                        # Plan DNS changes
./infra-deploy.sh pihole apply -- -var-file=blue.tfvars -backend-config=blue-config.s3.tfbackend

# For blue/green DNS deployments
cd infrastructure/dns/pihole
./tofu-ns.sh blue apply
./tofu-ns.sh green apply
```

### Ansible Usage

```bash
# Run Ansible playbook with inventory
ansible-playbook -i services/inventory.yml services/playbook.yml

# Run with specific tags
ansible-playbook -i services/inventory.yml services/playbook.yml --tags=tag1,tag2

# Limit to specific hosts
ansible-playbook -i services/inventory.yml services/playbook.yml --limit=host1

# Run test playbooks
cd services/nvidia-gpu && ansible-playbook -i test-inventory.yml test-playbook.yml
cd services/pihole && ansible-playbook -i test-inventory.yml test-playbook.yml
```

### Terraform/OpenTofu Usage

```bash
# Initialize working directory
tofu init -backend-config=config.s3.tfbackend

# Plan changes
tofu plan -var-file=terraform.tfvars

# Apply changes
tofu apply -var-file=terraform.tfvars

# Validate configuration
cd infrastructure/dns/[component] && tofu validate

# Format terraform files
tofu fmt -recursive infrastructure/
```

## Configuration Management

### Ansible Variables Hierarchy

1. Role defaults (`services/{service-name}/defaults/main.yml`)
2. Group variables (`services/group_vars/{group}.yml`)
3. Host variables (`services/host_vars/{hostname}.yml`)
4. Variables passed at runtime

### Template Usage

- Jinja2 templates for service configurations
- Template naming convention: `{filename}.j2`
- Templates located in role-specific `templates/` directories

### Secrets Management

- Example files (`main.example.yml`) provided for sensitive configs
- Actual configuration files excluded from repository
- Git-crypt used for securely storing sensitive configuration files

## Code Quality Tools

- **pre-commit**: Used for automated checks before commits
  - Automatically runs `tofu fmt` on `.tf` files to ensure consistent formatting
  - Configured in the repository root via `.pre-commit-config.yaml`
  - Other hooks like MegaLinter included for additional checks

- **MegaLinter**: Code quality and standards enforcement
  - Multiple linters for different file types
  - Two modes: incremental (pre-commit) and full (pre-push)

## Container Management

- We use podman with podman-docker compatibility layer
- Always use Docker CLI commands (not podman commands) for consistency
  ```bash
  # Examples of preferred commands
  docker ps
  docker compose up -d
  docker build
  ```
- The underlying implementation uses podman but we use docker CLI syntax
- Compose files used for multi-container services
- Watchtower handles automatic updates
- Service-specific compose files in templates directories
- Conditional IPv6 networking based on host capabilities
- For GPU access, avoid using docker/podman compose and use direct `docker run` commands with systemd services instead
- When GPU access is needed, use `--device nvidia.com/gpu=all --security-opt=label=disable` flags

## Network Management

### IPv4 and IPv6 Support

- Services support both IPv4 and IPv6 where possible
- IPv6 configuration in Docker is conditional based on host support
- Ansible facts (`ansible_all_ipv6_addresses`) used to detect IPv6 capability
- Templates automatically adapt to host networking capabilities
- Default fallback to IPv4-only when IPv6 is unavailable

## Testing & Validation

### Test Playbooks

- Service-specific test playbooks: `services/{service-name}/test-playbook.yml`
- Test inventory files: `services/{service-name}/test-inventory.yml`

### Validation Methods

- Service health checks after deployment
- Manual verification of functionality
- Monitoring alerts for service disruption
- DNS resolution tests using `dig` commands

## Technical Constraints

### Networking

- Services must be accessible within the local network
- DNS services must provide reliable resolution with redundancy
- Network segmentation may be in place for security

### Hardware

- Mixed environment of physical and virtual servers
- Varying hardware resources across servers
- UPS power backup for critical infrastructure