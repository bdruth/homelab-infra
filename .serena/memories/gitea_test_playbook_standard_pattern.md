# Gitea Test Playbook - Aligned with Standard Pattern

## Problem
The gitea test-playbook was using a completely different pattern from other services:
- **Other services**: Test on actual deployment hosts with real configuration
- **Gitea**: Test on localhost with fake test variables

## Root Cause Analysis
The localhost approach was a workaround for misaligned test tasks:
1. **Main tasks** (actual deployment): Docker Compose on Synology paths (`/volume1/docker/compose/gitea/`)
2. **Test tasks** (validation): Expected systemd service + wrong paths (`{{ gitea_install_dir }}`)
3. **Test playbook**: Ran on localhost to avoid the mismatch

## Solution Applied

### 1. Fixed Test Tasks (`tasks/test.yml`)
**Before** (systemd-based, misaligned):
- Expected `{{ gitea_install_dir }}` variable
- Checked for systemd service files
- Mixed systemd and container checks

**After** (Docker Compose-based, aligned):
- Uses actual Synology paths (`/volume1/docker/compose/gitea/`)
- Validates Docker Compose deployment
- Checks container status with `{{ docker_cmd }}`
- Tests HTTP connectivity
- Validates configuration files

### 2. Updated Test Playbook (`test-playbook.yml`)
**Before** (localhost testing):
```yaml
hosts: localhost
connection: local
vars:
  gitea_container_name: "gitea-test"
  gitea_data_dir: "/tmp/gitea-test"
```

**After** (standard pattern):
```yaml
hosts: gitea_hosts  # Real deployment hosts
become: true
# Uses actual production variables from vars/main.yml
```

## Benefits Achieved
- ✅ **Consistent pattern**: Same as disk-monitoring and gitea-act-runner
- ✅ **Real validation**: Tests actual deployment, not fake localhost setup
- ✅ **Proper alignment**: Test tasks match actual deployment method
- ✅ **Variable consistency**: Uses production variables, not test overrides
- ✅ **True verification**: Validates real Gitea provisioning on remote hosts

## Key Changes
1. **Removed systemd checks** from test tasks
2. **Added Docker Compose validation** matching actual deployment
3. **Changed from localhost to real hosts** in test playbook
4. **Used standard variable loading pattern** with `{{ playbook_dir }}`
5. **Aligned test paths with actual deployment paths**

## Verification
- ✅ Ansible-lint passes on all updated files
- ✅ Syntax check passes
- ✅ Consistent with other service test patterns
- ✅ Tests actual Synology Docker Compose deployment

Now the gitea test playbook properly validates the real Gitea deployment on remote hosts instead of running fake tests on localhost.