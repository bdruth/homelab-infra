# Design Patterns and Principles

## Architecture Overview

The homelab infrastructure follows a modular, layered architecture that enables independent service deployment while maintaining system cohesion:

1. **Infrastructure Provisioning Layer**: Using Terraform/OpenTofu to provision resources
   - DNS infrastructure (Pi-hole, dnsdist)
   - UPS monitoring resources
   - Cloud resources integration

2. **Configuration Layer**: Using Ansible to configure services
   - Service components deployment
   - Monitoring systems setup

3. **Service Layer**: The actual running services
   - Git services with CI/CD integration
   - DNS services for network resolution
   - Monitoring services for system observability

## Infrastructure as Code (IaC) Principles

- **Declarative Configuration**: The project uses declarative IaC tools (Terraform/OpenTofu, Ansible) to specify the desired state rather than imperative scripts.

- **Idempotence**: Operations can be applied multiple times without changing the result beyond the first application. This is a key principle, and specific patterns for achieving it are documented below.

- **Version Control**: All infrastructure definitions are stored in version control, allowing tracking of changes and rollbacks.

- **Modularity**: Infrastructure components are modularized for reuse (e.g., Terraform modules, Ansible roles).

## Key Technical Decisions

### 1. Service Deployment Strategy

**Pattern**: Role-Based Ansible Playbooks

- Each service is defined as an Ansible role with standardized structure
- Multiple deployment methods (standalone playbooks, combined infrastructure playbook)
- Dependency management through Ansible role metadata
- Separation of default configuration and environment-specific variables

### 2. Configuration Management

**Pattern**: Layered Configuration with Environment Overrides

- Default configurations defined within roles
- Environment-specific overrides in `group_vars` and `host_vars`
- Template-based configuration generation
- Secrets management via encrypted files

### 3. DNS Architecture

**Pattern**: High-Availability DNS with Ad Blocking

- Primary/secondary DNS server architecture
- DNS filtering via Pi-hole
- Advanced DNS routing via dnsdist
- DNS infrastructure managed via Terraform/OpenTofu

### 4. CI/CD Pipeline

**Pattern**: Self-hosted Git + CI/CD

- Gitea for Git repository hosting
- Gitea Actions for pipeline execution
- Multiple runner types for different workload requirements
- Gitea Act runners for GitHub Actions compatibility

### 5. Monitoring Solutions

**Pattern**: Component-Specific Monitoring with Centralized Dashboards

- Specialized monitoring for specific components (disks, UPS)
- Metrics collection via Telegraf
- Visualization via Grafana dashboards
- Integration with notification systems

## Network Configuration Patterns

### IPv6 Support

**Pattern**: Conditional IPv6 Network Configuration

- Docker networks conditionally enable IPv6 based on host capabilities
- Templates use the `ansible_default_ipv6` fact to reliably detect IPv6 support on the host.
- Network configuration is only applied when supported
- Services attach to IPv6-enabled networks when available

Example implementation:
```yaml
# Example from docker-compose template
{% if ansible_default_ipv6 %}
networks:
  net:
    driver: bridge
    enable_ipv6: true
{% endif %}

services:
  service_name:
    # service configuration
{% if ansible_default_ipv6 %}
    networks:
      - net
{% endif %}
```

## API Integration Patterns

### Grafana Alerting API Guidelines

**Pattern**: Standardized Grafana Alert Management

- **Permissions Handling**: Grafana OSS requires Admin role for alert management
- **Required Fields Structure**: Alert rules must have proper `folderUID`, `condition` reference, and datasource UIDs
- **Notification Policies**: Use `object_matchers` format for routing
- **Error Handling**: Include fallback to export JSON files when API permissions fail
- **Query Formatting**: Use visual query builder format in alert rules

## Development Standards

### Code Style Guidelines

1. **Infrastructure-as-Code Best Practices**:
   - Follow established IaC patterns and practices
   - Maintain consistent structure across similar resources
   - Use descriptive variable names

2. **Feature Management**:
   - Use consistent feature toggles with boolean variables
   - Implement conditional execution based on these variables

3. **Documentation and Readability**:
   - Include task comments describing purpose
   - Maintain consistent indentation in YAML files (2 spaces)
   - Document complex logic and decision points

4. **Error Handling**:
   - Handle errors with retries and proper ignore_errors handling
   - Register command outputs for validation and debugging

5. **Template Generation**:
   - When creating templates, use list building in Jinja2 to ensure proper indentation

6. **Service Management**:
   - When updating configuration files for services, ensure the service is restarted to apply the new configuration
   - For services that may take time to start, use Ansible's retry and until mechanisms instead of fixed delays

## Code Quality Tools

### Pre-commit Hooks

**Pattern**: Automated Quality Checks on Commit

- Pre-commit hooks run automatically when committing changes
- Different hooks perform specific checks based on file types
- Prevents committing code that doesn't meet quality standards
- Provides immediate feedback to developers

**Implementation**:

- Repository-level configuration in `.pre-commit-config.yaml`
- OpenTofu/Terraform formatting with `tofu fmt` on `.tf` files
- MegaLinter integration for comprehensive code quality checks

## Applied Design Patterns

1. **Infrastructure as Code** - Everything defined as code in version-controlled repositories
2. **Role-Based Configuration** - Modular components with clear responsibilities
3. **Configuration Templates** - Dynamic configuration generation from templates and variables
4. **High Availability Pairs** - Critical services deployed in redundant configurations
5. **Pipeline-Driven Deployments** - Changes deployed through automated pipelines
6. **Monitoring by Default** - All services integrate with monitoring systems
7. **Container-Based Services** - Services isolated in containers where appropriate
8. **Automated Updates** - Watchtower manages container updates automatically
9. **Adaptive Configuration** - Services configure themselves based on host capabilities (e.g., IPv6 support)
10. **Code Quality Automation** - Tools like pre-commit ensure consistent code formatting and quality

## Ansible Idempotency Patterns

This section outlines best practices for writing idempotent Ansible playbooks, based on recent refactoring efforts.

### 1. `group_by` Module

When using the `ansible.builtin.group_by` module to dynamically create groups, add `changed_when: false` to prevent the task from reporting changes on every run.

```yaml
- name: Add host to my_group
  ansible.builtin.group_by:
    key: "my_group"
  when: "'my_role' in hostvars[inventory_hostname].get('host_roles', [])"
  changed_when: false
```

### 2. `apt` Module

To prevent the `ansible.builtin.apt` module from reporting changes due to cache updates, use the `cache_valid_time` parameter. This ensures the cache is only updated if it's older than the specified time.

```yaml
- name: Update apt cache
  ansible.builtin.apt:
    update_cache: true
    cache_valid_time: 3600
```

### 3. Templates with Network Facts

When using network facts in templates, prefer stable facts to avoid unintended changes.

* Use `ansible_default_ipv6` instead of `ansible_all_ipv6_addresses` to check for IPv6 support, as the latter can be unstable due to temporary privacy addresses.
* For services that need to listen on a network interface, use `0.0.0.0` instead of a specific IP address like `ansible_default_ipv4.address`. This makes the service available on all interfaces and ensures the template's output is consistent.

### 4. Installation Scripts

When checking if a package installed via a script already exists, ensure the check is reliable.

* For shell-based installers that modify the environment (e.g., by adding to the `PATH` in `~/.bashrc`), use `bash -i -c` to run the check in an interactive shell that loads the user's profile.

```yaml
- name: Check if my_tool is installed
  ansible.builtin.command:
    cmd: bash -i -c "my_tool --version"
```

### 5. Service Management

* When using the `ansible.builtin.systemd` module, include `state: started` to ensure the task is idempotent and only reports a change if the service's state is actually modified.
* Before starting a service with a command (e.g., `docker compose up`), add a task to check if the service is already running. This prevents the start command from running unnecessarily.

### 6. Package Installation

Use dedicated Ansible modules for package installation instead of the `command` or `shell` modules. For example, use `ansible.builtin.pip` for Python packages, as it is designed to be idempotent.
