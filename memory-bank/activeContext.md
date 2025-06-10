# Active Context: Homelab Infrastructure

## Current Work Focus

The current focus of the homelab infrastructure project is on enhancing the CI/CD capabilities with Gitea Act Runners. This provides GitHub Actions compatibility to the self-hosted Gitea instance, allowing for more powerful workflow automation.

Key areas of active development:

1. **Gitea Act Runner Implementation**: Configuring and deploying Act runners for Gitea to enable GitHub Actions workflow compatibility
2. **Watchtower Integration**: Ensuring container-based services remain up-to-date with automated updates
3. **CI/CD Pipeline Improvements**: Enhancing existing Drone CI pipelines and integrating with the new Act runners

## Recent Changes

### Gitea Act Runner Implementation

- Created Ansible role for Gitea Act Runner deployment
- Developed test playbook for validation
- Added configuration templates for runner setup
- Created standalone deployment playbook (`ansible/gitea-act-runner-only.yml`)

### CI/CD Improvements

- Updated Drone CI configuration (`.drone.yml`)
- Added Gitea workflow testing (`.gitea/workflows/cache-test.yml`)
- Integrated with existing Drone runners

### Watchtower Configuration

- Set up Watchtower for automated Docker container updates
- Created test playbooks for validation

## Next Steps

1. **Complete Gitea Act Runner Testing**:

   - Validate the runner registration with Gitea
   - Test workflow execution
   - Document configuration options

2. **Enhance Monitoring**:

   - Add monitoring for the new CI/CD components
   - Create alerts for CI/CD pipeline failures
   - Implement dashboard for build status

3. **Documentation Updates**:

   - Update project documentation with new CI/CD capabilities
   - Create user guides for GitHub Actions compatibility
   - Document configuration patterns for pipelines

4. **Integration Testing**:
   - Test the complete CI/CD flow from code commit to deployment
   - Verify compatibility with existing workflows
   - Benchmark performance under various loads

## Active Decisions & Considerations

### Architecture Decisions

1. **Runner Deployment Strategy**:

   - Decision: Deploy Act runners as systemd services rather than containers
   - Rationale: Better integration with system resources and more direct control
   - Status: Implementation in progress

2. **Configuration Management**:

   - Decision: Use templated configuration with variable overrides
   - Rationale: Maintains consistency with other Ansible roles while allowing customization
   - Status: Implemented

3. **Authentication Handling**:
   - Decision: Use token-based authentication for runner registration
   - Rationale: Improved security and easier rotation of credentials
   - Status: Implementation in progress

### Open Questions

1. **Scaling Strategy**:

   - How many runners should be deployed per host?
   - Should runners be specialized for different types of workloads?
   - How to handle resource constraints during peak usage?

2. **Network Isolation**:

   - What level of network access should runners have?
   - How to securely provide access to internal services during CI/CD?
   - Should runners be placed in a separate network segment?

3. **Caching Strategy**:
   - How to implement efficient caching for builds?
   - Should cache storage be shared between runners?
   - How to manage cache lifecycle and eviction?

## Important Patterns & Preferences

### Code Organization

- Ansible roles follow the standard directory structure
- Services are deployed using individual roles with standalone playbooks
- Common configuration patterns are shared across roles

### Configuration Patterns

- Default configurations in `defaults/main.yml`
- Environment-specific overrides in `host_vars` and `group_vars`
- Sensitive information stored in separate, excluded files

### Deployment Process

- Test playbooks run before production deployment
- Incremental updates rather than full replacements
- Health checks performed after deployments

## Project Insights & Learnings

### Effective Approaches

- Modular Ansible roles enable reuse across different deployment scenarios
- Test playbooks provide quick validation of role functionality
- Template-based configurations reduce duplication

### Challenges & Solutions

- **Challenge**: Runner registration requires Gitea API access
  - **Solution**: Using registration tokens and secure API communication
- **Challenge**: Managing dependencies between services (Gitea → Act Runner → CI/CD workflows)
  - **Solution**: Clear documentation of dependencies and staged deployment
- **Challenge**: Keeping container-based services updated without interruption
  - **Solution**: Watchtower with appropriate update policies
- **Challenge**: GitHub Actions workflow commands failing with permission errors
  - **Solution**: Avoid using `sudo` in workflow commands since they already run as root in the Ubuntu runner

### Runtime Behavior

- Commands in GitHub Actions workflows run as `root` within the Ubuntu runner environment
- Adding `sudo` to commands like `apt update` or `apt-get install` causes errors
- Package installation and system commands should be executed directly without `sudo`
- Docker commands within workflows may still require special handling for permissions

### Process Improvements

1. Standardized test playbooks for all roles
2. Documentation templates for consistent information
3. Improved variable naming conventions for clarity
