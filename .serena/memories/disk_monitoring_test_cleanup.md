# Disk Monitoring Test Cleanup - Eliminated Redundant Files

## Problem
The disk-monitoring role had two separate test-related task files:
1. `tasks/main-test.yml` - Workaround file duplicating main tasks
2. `tasks/test.yml` - Actual validation test tasks

This was confusing and redundant.

## Root Cause
The `main-test.yml` was created as a workaround for the `role_path` variable issue when running test playbooks. The test playbook couldn't use the original `main.yml` because:
- `main.yml` used `{{ role_path }}` (only available in role context)
- Test playbooks don't have `role_path` defined

## Solution Applied
1. **Fixed the original `main.yml`** to work in both contexts:
   ```yaml
   - name: Set role directory path
     ansible.builtin.set_fact:
       disk_monitoring_role_path: "{{ role_path | default(playbook_dir) }}"
   ```

2. **Updated test-playbook.yml** to use proper paths:
   - Changed from relative paths to `{{ playbook_dir }}` paths
   - Removed `stat` checks (same issue as gitea-act-runner)
   - Used `failed_when: false` instead of `ignore_errors: true`

3. **Removed redundant file**: Deleted `tasks/main-test.yml`

## Changes Made
- **Modified**: `tasks/main.yml` - Added flexible path handling
- **Modified**: `test-playbook.yml` - Fixed variable loading and paths  
- **Deleted**: `tasks/main-test.yml` - No longer needed

## Benefits
- ✅ Single source of truth for main tasks
- ✅ No code duplication
- ✅ Cleaner project structure
- ✅ Same pattern as gitea-act-runner fix
- ✅ Works with both role execution and test playbooks

## Pattern Established
This creates a consistent pattern across all service test playbooks:
1. Use `{{ playbook_dir }}` for controller-local file paths
2. Direct variable loading without `stat` checks
3. Flexible path handling in main tasks using `role_path | default(playbook_dir)`
4. One `main.yml` that works in all contexts
5. One `test.yml` for validation tasks

## Verification
- ✅ Syntax check passes
- ✅ Ansible-lint passes  
- ✅ Reduced complexity
- ✅ Consistent with gitea-act-runner pattern