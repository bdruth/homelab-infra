# Gitea Act Runner Test Playbook - Complete Fix

## Problem Summary
The `services/gitea-act-runner/test-playbook.yml` had two major issues:
1. **Variable loading issue**: `gitea_act_runner_registration_token` was undefined
2. **Test mismatch issue**: Test tasks expected systemd deployment but actual deployment uses Docker Compose

## Root Causes & Solutions

### 1. Variable Loading Issue
**Problem**: Using `ansible.builtin.stat` to check variable files on remote hosts instead of local controller
**Solution**: Direct variable loading without conditional checks using `{{ playbook_dir }}` paths

### 2. Test Tasks Mismatch  
**Problem**: Test tasks were written for systemd/binary deployment but actual implementation uses Docker Compose
**Solution**: Completely rewrote test tasks to match Docker Compose deployment

## Changes Made

### Variable Loading (test-playbook.yml)
```yaml
# Before (failed)
- name: Check if host-specific variables exist
  ansible.builtin.stat:
    path: vars/main.yml  # Wrong: checks remote host
    
# After (working)
- name: Include host-specific variables
  ansible.builtin.include_vars:
    file: "{{ playbook_dir }}/vars/main.yml"  # Correct: local controller path
```

### Test Tasks (tasks/test.yml)
**Removed** (systemd-based tests):
- `gitea_act_runner_config_dir` usage
- `gitea_act_runner_bin_dir` usage  
- systemd service checks
- binary file checks

**Added** (Docker Compose tests):
- Directory structure validation
- Docker Compose file existence
- Container runtime verification
- Configuration validation
- Registration token verification

## Files Modified
1. `services/gitea-act-runner/test-playbook.yml` - Fixed variable loading paths
2. `services/gitea-act-runner/tasks/test.yml` - Complete rewrite for Docker deployment
3. `services/gitea-act-runner/tasks/main.yml` - Fixed container verification grep pattern

## Verification Results
- ✅ Variable `gitea_act_runner_registration_token` loads correctly
- ✅ Docker Compose template creation succeeds  
- ✅ All test tasks run without undefined variables
- ✅ Ansible-lint passes on all files
- ✅ Syntax validation passes

## Key Learnings
1. **Variable loading**: `stat` module runs on remote hosts, not controller
2. **Test alignment**: Test tasks must match actual deployment method (Docker vs systemd)
3. **Path resolution**: Use `{{ playbook_dir }}` for controller-local file paths
4. **Jinja escaping**: Use `{%raw%}` tags for Docker format strings in shell commands

The test playbook now correctly validates Docker Compose-based Gitea Act Runner deployments.