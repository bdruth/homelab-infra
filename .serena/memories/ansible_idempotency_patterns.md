# Ansible Idempotency Patterns

This document outlines best practices for writing idempotent Ansible playbooks, based on recent refactoring efforts.

## 1. `group_by` Module

When using the `ansible.builtin.group_by` module to dynamically create groups, add `changed_when: false` to prevent the task from reporting changes on every run.

```yaml
- name: Add host to my_group
  ansible.builtin.group_by:
    key: "my_group"
  when: "'my_role' in hostvars[inventory_hostname].get('host_roles', [])"
  changed_when: false
```

## 2. `apt` Module

To prevent the `ansible.builtin.apt` module from reporting changes due to cache updates, use the `cache_valid_time` parameter. This ensures the cache is only updated if it's older than the specified time.

```yaml
- name: Update apt cache
  ansible.builtin.apt:
    update_cache: true
    cache_valid_time: 3600
```

## 3. Templates with Network Facts

When using network facts in templates, prefer stable facts to avoid unintended changes.

* Use `ansible_default_ipv6` instead of `ansible_all_ipv6_addresses` to check for IPv6 support, as the latter can be unstable due to temporary privacy addresses.
* For services that need to listen on a network interface, use `0.0.0.0` instead of a specific IP address like `ansible_default_ipv4.address`. This makes the service available on all interfaces and ensures the template's output is consistent.

## 4. Installation Scripts

When checking if a package installed via a script already exists, ensure the check is reliable.

* For shell-based installers that modify the environment (e.g., by adding to the `PATH` in `~/.bashrc`), use `bash -i -c` to run the check in an interactive shell that loads the user's profile.

```yaml
- name: Check if my_tool is installed
  ansible.builtin.command:
    cmd: bash -i -c "my_tool --version"
```

## 5. Service Management

* When using the `ansible.builtin.systemd` module, include `state: started` to ensure the task is idempotent and only reports a change if the service's state is actually modified.
* Before starting a service with a command (e.g., `docker compose up`), add a task to check if the service is already running. This prevents the start command from running unnecessarily.

## 6. Package Installation

Use dedicated Ansible modules for package installation instead of the `command` or `shell` modules. For example, use `ansible.builtin.pip` for Python packages, as it is designed to be idempotent.