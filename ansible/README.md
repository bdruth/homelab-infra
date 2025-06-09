# Running ansible playbooks manually

1. Launch pkgx in a container -

```
docker run --rm -it \
  --dns <DNS_IP> \ # Useful when running the ansible playbooks for DNS
  -v "<PATH_TO_SSH_KEY>:/root/.ssh/id_rsa" \ # SSH key to use
  -v "$PWD:/opt/app" --workdir=/opt/app \ # mount the workspace into the container
  --env-file .env \ # load secrets from .env file
  pkgxdev/pkgx:v1 \ # this is the container we're running
  bash -c 'apt-get update && apt-get install -y dnsutils netcat-traditional; \ # container deps to install that aren't in pkgx
    pkgx +tofu +pip +ansible +ssh /bin/bash' # setup pkgx environment
```

2. Setup ansible by running `./setup-ansible.sh` inside the pkgx shell

3. Run ansible playbooks -

```
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ansible/nvidia-gpu/test-inventory.yml ansible/nvidia-gpu/main.yml
```

You may need to use `-i <HOST_IP>,` instead of the test-inventory.yml if one isn't available. Same for specifying the user and private-key, e.g. `-u <user> --private-key <PATH_TO_PRIVATE_KEY>`

# Running Gitea on Synology NAS

This repository includes a role for deploying Gitea on a Synology NAS using Docker.

## Prerequisites

- Synology NAS with Docker installed and running
- SSH access to the Synology NAS
- Docker installed on the NAS (typically at `/usr/local/bin/docker`)
- Docker Compose v2 support on the NAS

## Setup

1. Ensure your Synology NAS is added to your inventory file (see `inventory.yml`)

2. Check the host variables in `host_vars/synology1.yml` to ensure they match your environment

3. Run the Gitea playbook:

```
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ansible/inventory.yml ansible/gitea-only.yml
```

4. For testing connectivity before deploying, you can run:

```
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ansible/inventory.yml ansible/synology-gitea-test.yml
```

## Configuration

The Gitea role is configurable through variables in `host_vars/synology1.yml` including:

- Container name and image version
- User and group IDs
- Data directory paths
- HTTP and SSH ports
- Additional environment variables
- Docker labels for integration with tools like Watchtower
