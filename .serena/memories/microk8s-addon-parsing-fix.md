# MicroK8s Addon Management Bug Fix

## Issue Discovered
The MicroK8s addon enabling logic was flawed - it checked if addon names existed anywhere in `microk8s status` output, but this includes both enabled AND disabled addons.

## Root Cause
```yaml
# BROKEN - checks entire stdout including disabled addons
when: item not in microk8s_status_yaml.stdout
```

The `microk8s status --format yaml` shows ALL addons with their status:
```yaml
addons:
  - name: dns
    status: enabled
  - name: registry  
    status: disabled
```

## Solution Implemented
```yaml
# Parse enabled addons from status
- name: Parse enabled addons from status
  ansible.builtin.set_fact:
    microk8s_enabled_addons: "{{ (microk8s_status_yaml.stdout | from_yaml).addons | selectattr('status', 'equalto', 'enabled') | map(attribute='name') | list }}"

# Enable specified addons  
- name: Enable specified addons
  when:
    - item not in microk8s_enabled_addons  # Check against parsed enabled list
```

## Key Lessons
- **Parse YAML properly**: Use `from_yaml` filter instead of string matching
- **Filter by status**: Only compare against actually enabled addons
- **Test addon changes**: Verify new addons in inventory are actually enabled
- **Idempotency matters**: Ensure tasks only run when state change is needed

## Impact
- New addons added to `microk8s_addons_enabled` in inventory now work correctly
- Prevents unnecessary addon enable commands for already-enabled addons
- Maintains proper Ansible idempotency principles