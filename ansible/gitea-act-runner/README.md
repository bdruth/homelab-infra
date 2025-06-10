# Gitea Act Runner Role

This Ansible role deploys and configures a Gitea Act Runner using Docker Compose.

## Overview

The Gitea Act Runner role sets up a Docker-based runner for Gitea's Actions feature. It:

1. Creates necessary directories
2. Sets up the Docker Compose configuration
3. Launches the runner container
4. Handles registration with your Gitea instance
5. Manages the runner lifecycle

## Requirements

- Docker and Docker Compose installed on the target host
- Network connectivity to the Gitea instance
- Sufficient permissions to run Docker containers
- Sudo/root privileges (the role uses `become: yes` to create directories in /opt)

## Role Variables

### Default Variables (can be overridden)

```yaml
# Directory configuration
gitea_act_runner_dir: "/opt/gitea-act-runner"

# Runner configuration
gitea_act_runner_name: "{{ inventory_hostname }}"
gitea_act_runner_labels: "ubuntu-latest:docker://node:20-bookworm"

# Docker configuration
gitea_act_runner_privileged: false

# Gitea instance URL
gitea_act_runner_instance_url: "https://gitea.example.com/"
```

### Required Variables (store in vars/main.yml)

```yaml
# Registration token for the Gitea Act Runner
gitea_act_runner_registration_token: "your-token-here"
```

## Example Usage

### Adding to inventory.yml

```yaml
asrock-nuc:
  ansible_host: 192.168.x.y
  ansible_user: foobar
  host_roles: [gitea-act-runner]
```

### Running the role

```bash
ansible-playbook -i inventory.yml ansible/gitea-act-runner/main.yml
```

## Runner Labels

The runner can be configured with custom labels to define the environments it supports. The default is `ubuntu-latest:docker://node:20-bookworm`, which provides a Node.js environment.

## Security Considerations

- The runner container needs access to the Docker socket to create containers for running actions.
- Consider the security implications of runner registration tokens.
- The runner by default runs in non-privileged mode for better security. Set `gitea_act_runner_privileged: true` if privileged mode is required.
