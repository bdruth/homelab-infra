# Gitea Act Runner Test Playbook Variable Loading Fix

## Issue
The `gitea-act-runner/test-playbook.yml` was failing with:
```
AnsibleUndefinedVariable: 'gitea_act_runner_registration_token' is undefined
```

## Root Cause
The test playbook was using relative paths like `defaults/main.yml` and `vars/main.yml` to load variables, but when running from the services directory, these paths were resolved relative to the current working directory, not the role directory.

## Solution
Updated the test playbook to use `{{ playbook_dir }}` variable to ensure proper path resolution:

- Changed `defaults/main.yml` → `{{ playbook_dir }}/defaults/main.yml`
- Changed `vars/main.yml` → `{{ playbook_dir }}/vars/main.yml`  
- Changed `tasks/main.yml` → `{{ playbook_dir }}/tasks/main.yml`
- Changed `tasks/test.yml` → `{{ playbook_dir }}/tasks/test.yml`

## Key Variable
The `gitea_act_runner_registration_token` variable is defined in `services/gitea-act-runner/vars/main.yml` and is required by the Docker Compose template.

## Verification
- ✅ Syntax check passes: `ansible-playbook --syntax-check test-playbook.yml`
- ✅ Linting passes: `ansible-lint test-playbook.yml`

## Test Usage
Run from the gitea-act-runner directory:
```bash
cd services/gitea-act-runner
ansible-playbook test-playbook.yml -i ../../inventory.yml
```