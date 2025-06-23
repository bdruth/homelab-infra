# Active Context: Homelab Infrastructure

## Current Work Focus

The current focus is on enhancing the CI/CD capabilities with Gitea Act Runners, improving networking support in containerized services, and standardizing the monitoring infrastructure:

1. **Gitea Act Runner Implementation**: Configuring and deploying Act runners for Gitea to enable GitHub Actions workflow compatibility
2. **Watchtower Integration**: Ensuring container-based services remain up-to-date with automated updates
3. **CI/CD Pipeline Improvements**: Enhancing existing Drone CI pipelines and integrating with the new Act runners
4. **IPv6 Support**: Adding conditional IPv6 support for containerized services based on host capabilities
5. **Monitoring Infrastructure Standardization**: Refactoring monitoring components to follow consistent patterns

## Recent Changes

### Code Quality Tooling: pre-commit with tofu fmt
- Added pre-commit configuration to automate Terraform/OpenTofu code formatting
- Set up a local hook to run `tofu fmt` on all `.tf` files during commit
- Applied consistent formatting to all existing Terraform files using `tofu fmt -recursive`

### CI/CD Migration: Drone to Gitea Actions
- Converted the DNS infrastructure deployment from Drone CI to Gitea Actions
- Created a descriptive workflow name "DNS Infrastructure Deployment" to replace generic "build"
- Leveraged Gitea Actions path-based filtering to simplify the workflow
- Ensured consistent notification patterns with existing workflows
- Updated system documentation to reflect the CI/CD architecture changes
- Removed redundant Drone configuration (`.drone.yml`)

### Monitoring Infrastructure Refactoring
- Integrated disk-monitoring into the main ansible infrastructure
- Converted standalone disk-monitoring setup to a proper ansible role
- Created disk-monitoring-only.yml for standalone deployment
- Moved Grafana dashboard creation tools to ansible/tools/grafana
- Fixed Telegraf configuration issues with mount point monitoring

### Gitea Act Runner Implementation
- Created Ansible role for Gitea Act Runner deployment
- Developed test playbook for validation
- Added configuration templates for runner setup
- Created standalone deployment playbook (`ansible/gitea-act-runner-only.yml`)

## Next Steps

1. **Validate Disk Monitoring Configuration**:
   - Confirm Telegraf configuration works on all host types
   - Verify metrics are properly collected in InfluxDB
   - Test Grafana dashboard creation tools

2. **Complete Gitea Act Runner Testing**:
   - Validate the runner registration with Gitea
   - Test workflow execution
   - Document configuration options

3. **Enhance Monitoring**:
   - Add monitoring for the new CI/CD components
   - Create alerts for CI/CD pipeline failures
   - Implement dashboard for build status

4. **Documentation Updates**:
   - Update project documentation with new CI/CD capabilities
   - Create user guides for GitHub Actions compatibility
   - Document configuration patterns for pipelines

## Active Decisions & Considerations

### Architecture Decisions

1. **Runner Deployment Strategy**:
   - Decision: Deploy Act runners as systemd services rather than containers
   - Rationale: Better integration with system resources and more direct control

2. **Configuration Management**:
   - Decision: Use templated configuration with variable overrides
   - Rationale: Maintains consistency with other Ansible roles while allowing customization

3. **Authentication Handling**:
   - Decision: Use token-based authentication for runner registration
   - Rationale: Improved security and easier rotation of credentials

### Open Questions

1. **Scaling Strategy**:
   - How many runners should be deployed per host?
   - Should runners be specialized for different types of workloads?

2. **Network Isolation**:
   - What level of network access should runners have?
   - How to securely provide access to internal services during CI/CD?

## Runtime Behavior

- Commands in GitHub Actions workflows run as `root` within the Ubuntu runner environment
- Adding `sudo` to commands like `apt update` or `apt-get install` causes errors
- Package installation and system commands should be executed directly without `sudo`