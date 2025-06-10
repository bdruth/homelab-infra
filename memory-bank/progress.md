# Progress: Homelab Infrastructure

## What Works

### Core Infrastructure

- ✅ **Ansible-based Deployment**: Working deployment system with standardized roles and playbooks
- ✅ **DNS Management**: Functional Pi-hole and dnsdist configuration for DNS management
- ✅ **Git Service**: Gitea installed and operational
- ✅ **CI/CD Fundamentals**: Working Drone CI setup with execution runners

### Monitoring

- ✅ **Disk Monitoring**: Working Telegraf + Grafana setup for disk status monitoring
- ✅ **UPS Monitoring**: Power supply monitoring implementation

### Deployment Tools

- ✅ **Deployment Scripts**: Working deployment scripts for various environments
  - `ansible-deploy.sh`: Standard Ansible deployment
  - `pkgx-deploy.sh`: Alternative package manager deployment
  - `setup-ansible.sh`: Ansible environment setup

## In Progress

### CI/CD Enhancements

- 🔄 **Gitea Act Runners**: Implementing GitHub Actions compatibility
  - Base role created
  - Test playbook created
  - Default configuration established
  - Systemd service templates prepared
  - Runner registration mechanism in development
  - First workflow execution tests completed
  - Identified and resolved permission issues with `sudo` commands in Ubuntu runner environment

### Container Management

- 🔄 **Watchtower Implementation**: Automating container updates
  - Base configuration established
  - Test playbooks created
  - Integration with existing services in progress

### Documentation

- 🔄 **Workflow Documentation**: Documenting GitHub Actions compatibility
- 🔄 **Role Documentation**: Improving documentation for newer roles

## What's Left to Build

### Monitoring Enhancements

- 📋 **CI/CD Monitoring**: Add monitoring for CI/CD pipeline status
- 📋 **Service Health Dashboards**: Comprehensive dashboards for all services
- 📋 **Centralized Logging**: Implement a centralized logging solution

### Infrastructure Improvements

- 📋 **High Availability**: Enhance redundancy for critical services
- 📋 **Backup Strategy**: Implement automated backups for all services
- 📋 **Multi-site Support**: Support for services across multiple physical locations

### Security Enhancements

- 📋 **TLS Everywhere**: Ensure all service communications use TLS
- 📋 **Secret Rotation**: Implement automated secret rotation
- 📋 **Network Policy Enforcement**: Stricter network isolation between services

## Current Status

| Component              | Status         | Priority | Notes                                     |
| ---------------------- | -------------- | -------- | ----------------------------------------- |
| **Gitea Act Runners**  | 🔄 In Progress | High     | Implementing GitHub Actions compatibility |
| **Watchtower**         | 🔄 In Progress | Medium   | Automating container updates              |
| **Disk Monitoring**    | ✅ Complete    | N/A      | Working as expected                       |
| **UPS Monitoring**     | ✅ Complete    | N/A      | Working as expected                       |
| **DNS Infrastructure** | ✅ Complete    | N/A      | Working with high availability            |
| **Drone CI**           | ✅ Complete    | N/A      | Working with exec runners                 |
| **CI/CD Monitoring**   | 📋 Not Started | Medium   | Needed for better visibility              |
| **Service Backups**    | 📋 Not Started | High     | Critical for disaster recovery            |

## Known Issues

### Gitea Act Runner

1. **Issue**: Registration token handling needs improvement

   - **Status**: Under investigation
   - **Impact**: Potential security concern
   - **Workaround**: Using temporary tokens until fixed

2. **Issue**: Resource consumption may be high during intensive workflows

   - **Status**: Monitoring
   - **Impact**: Could affect host performance
   - **Workaround**: Limiting concurrent jobs

3. **Issue**: Permission errors when using `sudo` in GitHub Actions workflows
   - **Status**: Resolved
   - **Impact**: Failed workflow executions
   - **Solution**: Remove `sudo` from commands as they already run as root in the Ubuntu runner environment
   - **Note**: Affects commands like `apt update`, `apt-get install`, etc. which should be run directly

### Watchtower

1. **Issue**: Update timing may disrupt service availability
   - **Status**: Investigating
   - **Impact**: Brief service interruptions
   - **Workaround**: Scheduling updates during low-usage periods

### General Infrastructure

1. **Issue**: Domain name resolution occasionally slow
   - **Status**: Investigating
   - **Impact**: Slight delay in service access
   - **Workaround**: DNS caching adjustments

## Evolution of Project Decisions

### CI/CD Strategy

- **Initial Approach**: Drone CI with exec runners only
- **Current Approach**: Hybrid approach using both Drone CI and Gitea Act Runners
- **Rationale**: Better compatibility with GitHub Actions workflows while maintaining existing Drone pipelines

### Service Deployment

- **Initial Approach**: Ad-hoc Ansible playbooks
- **Current Approach**: Standardized roles with both standalone and combined playbooks
- **Rationale**: Improved modularity, reusability, and consistency

### Monitoring

- **Initial Approach**: Service-specific monitoring only
- **Current Approach**: Component-specific monitoring with integration paths
- **Current Goal**: Comprehensive, centralized monitoring solution
- **Rationale**: Better visibility across all infrastructure components

### DNS Management

- **Initial Approach**: Single Pi-hole instance
- **Current Approach**: High-availability Pi-hole with dnsdist
- **Rationale**: Improved reliability and performance for critical network services

### Containerization Strategy

- **Initial Approach**: Mix of containerized and non-containerized services
- **Current Approach**: Containerization where appropriate with automated updates
- **Rationale**: Improved isolation and easier updates while maintaining performance

## Learning Points & Project Evolution

### Successful Patterns

1. **Standardized Role Structure**: Consistent approach to service roles improves maintainability
2. **Test Playbooks**: Dedicated test playbooks for each role simplifies validation
3. **Template-based Configuration**: Jinja2 templates with variable overrides provides flexibility

### Abandoned Approaches

1. **Manual Container Updates**: Replaced with Watchtower for automation
2. **Direct Runner Execution**: Replaced with systemd service management for better lifecycle control
3. **Static DNS Configuration**: Replaced with dynamic, high-availability solution

### Future Direction

1. **Expand Monitoring**: Comprehensive monitoring across all services
2. **Enhance Automation**: Further reduce manual intervention in maintenance tasks
3. **Improve Documentation**: Better documentation for complex deployment scenarios
4. **Integration Testing**: More thorough testing of interactions between components
