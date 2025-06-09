# Gitea Role for Synology NAS

This role deploys and manages a Gitea instance using Docker on a Synology NAS running DSM.

## Requirements

- Synology NAS with Docker installed and running
- SSH access to the Synology NAS
- Ansible 2.9 or later
- Docker Compose v2 installed on the Synology NAS

## Role Structure

- `main.yml` - Main playbook for the role
- `tasks/main.yml` - Tasks for deploying Gitea
- `templates/gitea-docker-compose.yml.j2` - Docker Compose template
- `vars/main.yml` - Default variables
- `vars/main.example.yml` - Example variables

## Variables

| Variable               | Description                             | Default                     |
| ---------------------- | --------------------------------------- | --------------------------- |
| `gitea_version`        | Gitea Docker image version              | `latest`                    |
| `gitea_container_name` | Docker container name                   | `gitea`                     |
| `gitea_user_uid`       | UID for the Gitea user                  | `1026`                      |
| `gitea_user_gid`       | GID for the Gitea user                  | `100`                       |
| `gitea_data_dir`       | Directory to store Gitea data           | `/volume1/docker/gitea`     |
| `gitea_http_port`      | HTTP port for Gitea                     | `3000`                      |
| `gitea_ssh_port`       | SSH port for Gitea                      | `222`                       |
| `gitea_extra_env`      | Map of additional environment variables | -                           |
| `gitea_labels`         | Map of Docker labels                    | Default: Watchtower enabled |

## Usage

### Basic Usage

1. Add your Synology NAS to your inventory file:

```yaml
all:
  children:
    nas:
      hosts:
        synology:
          ansible_host: 192.168.1.x
          ansible_user: admin
          ansible_ssh_pass: your_password # Or use SSH keys
```

2. Run the gitea-only playbook:

```bash
ansible-playbook -i inventory.yml gitea-only.yml
```

### Advanced Configuration

For more advanced configuration, create host-specific variables:

```yaml
# In host_vars/synology.yml
gitea_http_port: "8080"
gitea_ssh_port: "2222"
gitea_extra_env:
  DOMAIN: "git.example.com"
  ROOT_URL: "https://git.example.com"
```

## Notes

- This role is specifically designed to be compatible with Synology DSM
- Docker auto-restart is handled by DSM, so no systemd service is needed
- On Synology NAS, the Docker command is expected to be at `/usr/local/bin/docker` (the role handles this automatically)
- The role handles detection of Synology DSM and adjusts paths accordingly
