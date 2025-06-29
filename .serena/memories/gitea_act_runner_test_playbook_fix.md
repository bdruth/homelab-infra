# Gitea Act Runner Test Playbook Fix

## Issue
The `services/gitea-act-runner/test-playbook.yml` was failing with:
```
AnsibleUndefinedVariable: 'gitea_act_runner_registration_token' is undefined
```

## Root Cause
The test playbook was using `ansible.builtin.stat` to check for the existence of variable files on the **remote host** instead of the **local Ansible controller**. Since the variable files only exist on the controller (where the playbook runs), the `stat` check always returned `False`, causing the variables to never be loaded.

## Solution
1. **Removed conditional checks**: Eliminated the `stat` module checks for variable file existence
2. **Direct variable loading**: Changed to directly load both `defaults/main.yml` and `vars/main.yml` without conditions
3. **Fixed container verification**: Corrected the container name from "watchtower" to "gitea-act-runner" in the verification task
4. **Fixed shell pipefail**: Used proper bash shell with pipefail option for the container check

## Key Changes
- **Variable loading**: No more `stat` checks, direct `include_vars` for both default and production variables
- **Container check**: Changed from `grep watchtower` to `grep gitea-act-runner`
- **Shell safety**: Used `executable: /bin/bash` with proper pipefail handling

## Files Modified
- `services/gitea-act-runner/test-playbook.yml` - Fixed variable loading paths
- `services/gitea-act-runner/tasks/main.yml` - Fixed container verification logic

## Verification
- ✅ Variable `gitea_act_runner_registration_token` now loads correctly
- ✅ Docker Compose template creation succeeds
- ✅ Ansible-lint passes
- ✅ Syntax check passes

The test playbook now works correctly for testing the gitea-act-runner service deployment.