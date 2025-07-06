# Test Playbook Combined Play Pattern

## Problem Identified
Some test playbooks were separating role application and test tasks into two different plays:

```yaml
# Problematic approach - separates role application and test tasks
- name: Apply Role
  hosts: role_hosts
  become: true
  gather_facts: true
  roles:
    - role_name

- name: Run Tests
  hosts: role_hosts
  become: true
  gather_facts: true
  tasks:
    - name: Import test tasks
      ansible.builtin.import_tasks: "tasks/test.yml"
```

This approach causes variables defined in the role (like those in `defaults/main.yml`) to be unavailable during test task execution because each play creates a new variable context.

## Solution: Combined Play Pattern
The solution is to combine the role application and test tasks into a single play:

```yaml
# Correct approach - role and test tasks in a single play
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

## Benefits
- ✅ Role variables are available to test tasks
- ✅ Maintains proper variable precedence
- ✅ Ensures test tasks run in the same context as the role
- ✅ Prevents "variable undefined" errors
- ✅ Simplifies playbook structure

## Implementation
This pattern has been confirmed working in:
- Drone CI test playbook
- Watchtower test playbook

## Example Implementation
Before:
```yaml
- name: Import Drone CI configuration playbook
  hosts: drone_hosts
  become: true
  gather_facts: true
  roles:
    - drone

- name: Validate Drone CI configuration
  hosts: drone_hosts
  become: true
  gather_facts: true
  tasks:
    - name: Import Drone test tasks
      ansible.builtin.import_tasks: "tasks/test.yml"
```

After:
```yaml
- name: Import Drone CI configuration and run tests
  hosts: drone_hosts
  become: true
  gather_facts: true
  roles:
    - drone
  tasks:
    - name: Import Drone test tasks
      ansible.builtin.import_tasks: "tasks/test.yml"
```

## Additional Notes
- This pattern is particularly important when test tasks reference variables defined in the role's defaults or vars
- The pattern complements the "Test Playbook Variable Precedence Pattern" by ensuring proper variable context
- Ensures that conditional statements in test tasks (like `when: install_role | bool`) can access role variables