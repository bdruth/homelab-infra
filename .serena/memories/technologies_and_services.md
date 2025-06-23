# Technologies and Services

## Core Infrastructure Management

| Technology             | Purpose                                      | Version Info                          |
| ---------------------- | -------------------------------------------- | ------------------------------------- |
| **Ansible**            | Configuration management, service deployment | Used for all service configurations   |
| **Terraform/OpenTofu** | Infrastructure provisioning, DNS management  | Used for DNS configuration            |
| **Docker**             | Container runtime                            | Used for containerized services       |
| **Git**                | Version control                              | Core to all infrastructure management |
| **pkgx**               | Tool dependency management                   | Used for deployment scripts           |
| **git-crypt**          | Secrets management                           | Encrypts sensitive files in repo      |
| **pre-commit**         | Git hooks management                         | Automates code quality checks         |
| **MegaLinter**         | Code quality tool                           | Multiple linters for different files  |

## Services & Applications

| Service              | Purpose                           | Implementation                           |
| -------------------- | --------------------------------- | ---------------------------------------- |
| **Gitea**            | Self-hosted Git service           | Deployed via Ansible                     |
| **Drone CI**         | Continuous Integration/Deployment | Server and various runners               |
| **Gitea Act Runner** | GitHub Actions compatibility      | Allows GitHub Actions workflow execution |
| **Pi-hole**          | DNS ad blocking                   | Primary/secondary deployment for HA      |
| **dnsdist**          | DNS load balancing, routing       | Handles advanced DNS functionality       |
| **Watchtower**       | Automated container updates       | Keeps Docker containers updated          |
| **Network UPS Tools** | UPS monitoring and management     | Power supply monitoring                  |

## Monitoring & Observability

| Tool               | Purpose                 | Components                                |
| ------------------ | ----------------------- | ----------------------------------------- |
| **Telegraf**       | Metrics collection      | Used for disk monitoring                  |
| **Grafana**        | Metrics visualization   | Creates dashboards for monitoring data    |
| **UPS Monitoring** | Power supply monitoring | Custom implementation                     |
| **Grafana Tools**  | Dashboard management    | Creates and updates monitoring dashboards |

## Special Purpose Services

| Service              | Purpose                           | Implementation                           |
| -------------------- | --------------------------------- | ---------------------------------------- |
| **NVIDIA GPU Support** | GPU access for containerized apps | Configuration and driver management      |
| **Network UPS Tools** | UPS management                   | Monitoring and safe shutdown             |

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