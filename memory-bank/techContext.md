# Technical Context: Homelab Infrastructure

## Technologies Used

### Core Infrastructure Management

| Technology             | Purpose                                      | Version Info                          |
| ---------------------- | -------------------------------------------- | ------------------------------------- |
| **Ansible**            | Configuration management, service deployment | Used for all service configurations   |
| **Terraform/OpenTofu** | Infrastructure provisioning, DNS management  | Used for DNS configuration            |
| **Docker**             | Container runtime                            | Used for containerized services       |
| **Git**                | Version control                              | Core to all infrastructure management |

### Services & Applications

| Service              | Purpose                           | Implementation                           |
| -------------------- | --------------------------------- | ---------------------------------------- |
| **Gitea**            | Self-hosted Git service           | Deployed via Ansible                     |
| **Drone CI**         | Continuous Integration/Deployment | Server and various runners               |
| **Gitea Act Runner** | GitHub Actions compatibility      | Allows GitHub Actions workflow execution |
| **Pi-hole**          | DNS ad blocking                   | Primary/secondary deployment for HA      |
| **dnsdist**          | DNS load balancing, routing       | Handles advanced DNS functionality       |
| **Watchtower**       | Automated container updates       | Keeps Docker containers updated          |

### Monitoring & Observability

| Tool               | Purpose                 | Components                                |
| ------------------ | ----------------------- | ----------------------------------------- |
| **Telegraf**       | Metrics collection      | Used for disk monitoring                  |
| **Grafana**        | Metrics visualization   | Creates dashboards for monitoring data    |
| **UPS Monitoring** | Power supply monitoring | Custom implementation                     |
| **Grafana Tools**  | Dashboard management    | Creates and updates monitoring dashboards |

## Development Environment

### Required Tools

- **Ansible**: For running playbooks and roles
- **Terraform/OpenTofu**: For managing DNS infrastructure
- **Git**: For version control and interaction with Gitea
- **Docker**: For container management
- **pkgx**: Alternative package manager used in some deployment scripts

### Repository Structure

```
homelab-infra/
├── ansible/                   # Ansible playbooks and roles
│   ├── {service-name}/        # Service-specific roles
│   ├── {service-name}-only.yml # Standalone service playbooks
│   ├── infrastructure.yml     # Combined infrastructure playbook
│   └── tools/                 # Shared tools used across roles
│       └── grafana/           # Grafana dashboard creation tools
├── dns/                       # DNS configuration
│   ├── dns-ha/                # High-availability DNS configs
│   └── pihole/                # Pi-hole specific configs
├── modules/                   # Reusable Terraform modules
├── ups-monitoring/            # UPS monitoring configuration
├── ansible-deploy.sh          # Ansible deployment script
├── pkgx-deploy.sh             # pkgx-based deployment
└── README.md                  # Project documentation
```

### Deployment Patterns

1. **Standalone Service Deployment**:

   ```bash
   ./ansible-deploy.sh ansible/{service-name}-only.yml
   ```

2. **Full Infrastructure Deployment**:

   ```bash
   ./ansible-deploy.sh ansible/infrastructure.yml
   ```

3. **pkgx-based Deployment** (alternative package manager):
   ```bash
   ./pkgx-deploy.sh
   ```

## Technical Constraints

### Networking

- Services must be accessible within the local network
- DNS services must provide reliable resolution with redundancy
- Network segmentation may be in place for security

### Hardware

- Mixed environment of physical and virtual servers
- Varying hardware resources across servers
- UPS power backup for critical infrastructure

### Security

- Secrets management through encrypted files
- Network isolation for sensitive services
- Regular updates via Watchtower for containerized services

## Dependencies & Integrations

### Core Dependencies

- **Ansible**: Python dependencies for specific modules
- **Terraform/OpenTofu**: Provider plugins for specific functionality
- **Docker**: Container runtime and images
- **DNS**: Upstream DNS providers for forwarding

### Service Dependencies

- **Drone CI**: Depends on Gitea for authentication and webhooks
- **Drone Runners**: Depend on Drone CI server
- **Gitea Act Runners**: Depend on Gitea for job coordination
- **Monitoring**: Depends on metrics collection and storage

### External Integrations

- DNS resolution with upstream providers
- Certificate management for secure services
- Potential cloud service integrations

## Configuration Management

### Ansible Variables

Configuration hierarchy:

1. Role defaults (`ansible/{service-name}/defaults/main.yml`)
2. Group variables (`ansible/group_vars/{group}.yml`)
3. Host variables (`ansible/host_vars/{hostname}.yml`)
4. Variables passed at runtime

### Template Usage

- Jinja2 templates for service configurations
- Template naming convention: `{filename}.j2`
- Templates located in role-specific `templates/` directories

### Secrets Management

- Example files (`main.example.yml`) provided for sensitive configs
- Actual configuration files excluded from repository
- Git-crypt or similar tools may be used for encrypted files

## Testing & Validation

### Test Playbooks

Service-specific test playbooks:

- `ansible/{service-name}/test-playbook.yml`

### Validation Methods

- Service health checks after deployment
- Manual verification of functionality
- Monitoring alerts for service disruption

## Tool Usage Patterns

### Ansible Usage

```bash
# Run playbook with inventory
ansible-playbook -i ansible/inventory.yml ansible/playbook.yml

# Run with specific tags
ansible-playbook -i ansible/inventory.yml ansible/playbook.yml --tags=tag1,tag2

# Limit to specific hosts
ansible-playbook -i ansible/inventory.yml ansible/playbook.yml --limit=host1
```

### Terraform/OpenTofu Usage

```bash
# Initialize working directory
tofu init -backend-config=config.s3.tfbackend

# Plan changes
tofu plan -var-file=terraform.tfvars

# Apply changes
tofu apply -var-file=terraform.tfvars
```

### Docker Management

- Compose files used for multi-container services
- Watchtower handles automatic updates
- Service-specific compose files in templates directories
- Conditional IPv6 networking based on host capabilities
- Network configuration through docker-compose templates

### Network Management

#### IPv4 and IPv6 Support

- Services support both IPv4 and IPv6 where possible
- IPv6 configuration in Docker is conditional based on host support
- Ansible facts (`ansible_all_ipv6_addresses`) used to detect IPv6 capability
- Templates automatically adapt to host networking capabilities
- Default fallback to IPv4-only when IPv6 is unavailable
