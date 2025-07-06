# Test Playbook Variable Precedence Pattern

## Problem Identified
Some test playbooks were manually loading variables using `ansible.builtin.include_vars`, which overrides Ansible's normal variable precedence:

```yaml
# Problematic approach - overrides variable precedence
tasks:
  - name: Include role default variables for validation
    ansible.builtin.include_vars:
      file: "defaults/main.yml"

  - name: Include host-specific variables for validation
    ansible.builtin.include_vars:
      file: "vars/main.yml" 
    failed_when: false
```

This approach causes several issues:
- Inventory variables (which should override defaults) are ignored
- Host-specific variable customizations don't apply during testing
- Tests may pass on incorrect configurations that would fail in production

## Standard Pattern Solution
The standard pattern for test playbooks should:

1. **Rely on Ansible's built-in variable precedence**
2. **Avoid manually loading variables with include_vars**
3. **Import only the test tasks**
4. **Keep role application and test tasks in the same play** (see test_playbook_combined_play_pattern memory)

```yaml
# Correct approach - maintains proper variable precedence
- name: Apply Role and Run Tests
  hosts: role_hosts
  become: true
  gather_facts: true
  roles:
    - role_name
  tasks:
    - name: Import test tasks
      ansible.builtin.import_tasks: "tasks/test.yml"
```

## Ansible Variable Precedence (from lowest to highest)
1. Role defaults (defined in `defaults/main.yml`)
2. Inventory variables (defined in inventory files)
3. Group variables (from `group_vars/`)
4. Host variables (from `host_vars/`)
5. Role and include variables (defined in `vars/main.yml`)
6. Block variables
7. Task variables
8. Extra variables (set with `-e` on command line)

## Benefits
- ✅ Proper respect for variable overrides in inventory
- ✅ Consistent testing of actual deployment configuration
- ✅ Tests validate the real configuration used in production
- ✅ Follows Ansible best practices for variable handling
- ✅ Simplified test playbook structure
- ✅ Role variables available to test tasks in same play (critical for conditionals)

## Implementation
This pattern has been implemented in:
- NUT test playbook
- Drone Runner Exec test playbook
- Gitea test playbook
- Gitea Act Runner test playbook
- Drone CI test playbook
- Watchtower test playbook

## Additional Notes
- Test tasks should be written to work with proper variable precedence
- The `tasks/test.yml` file should validate the actual deployed configuration
- No need to load variables manually when proper role structure is followed
- For details on combining role application and tests in a single play, see the "test_playbook_combined_play_pattern" memory