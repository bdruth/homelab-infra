# Services Directory

This directory contains service configurations and deployment playbooks for the homelab infrastructure.

## Structure

- Individual service directories containing role definitions
- `*-only.yml` files for standalone service deployments
- `infrastructure.yml` for combined infrastructure deployment
- Configuration files and templates for each service

## Usage

Services can be deployed individually or as part of the complete infrastructure using the deployment scripts:

```bash
./services-deploy.sh services/{service-name}-only.yml  # Deploy single service
./services-deploy.sh services/infrastructure.yml       # Deploy full infrastructure
```

## Available Services

- DNS management (Pi-hole, DNSDist)
- Git services (Gitea, Gitea Act Runner)
- CI/CD (Drone CI, Drone Runners)
- Monitoring (UPS monitoring, disk monitoring)
- Utilities (Watchtower)
- GPU services (NVIDIA GPU configuration)

## Running services playbooks manually

1. Launch pkgx in a container:

```bash
docker run --rm -it \
  --dns <DNS_IP> \ # Useful when running the playbooks for DNS
  -v "<PATH_TO_SSH_KEY>:/root/.ssh/id_rsa" \ # SSH key to use
  -v "$PWD:/opt/app" --workdir=/opt/app \ # mount the workspace into the container
  --env-file .env \ # load secrets from .env file
  pkgxdev/pkgx:v1 \ # this is the container we're running
  bash -c 'apt-get update && apt-get install -y dnsutils netcat-traditional; \ # container deps to install that aren't in pkgx
    pkgx +tofu +pip +ansible +ssh /bin/bash' # setup pkgx environment
```

2. Setup services by running `./setup-services.sh` inside the pkgx shell

3. Run playbooks:

```bash
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i services/nvidia-gpu/test-inventory.yml services/nvidia-gpu/main.yml
```

You may need to use `-i <HOST_IP>,` instead of the test-inventory.yml if one isn't available. Same for specifying the user and private-key, e.g. `-u <user> --private-key <PATH_TO_PRIVATE_KEY>`

## Running Gitea on Synology NAS

This repository includes a role for deploying Gitea on a Synology NAS using Docker.

### Prerequisites

- Synology NAS with Docker installed and running
- SSH access to the Synology NAS
- Docker installed on the NAS (typically at `/usr/local/bin/docker`)
- Docker Compose v2 support on the NAS

### Setup

1. Ensure your Synology NAS is added to your inventory file (see `inventory.yml`)

2. Check the host variables in `host_vars/synology1.yml` to ensure they match your environment

3. Run the Gitea playbook:

```bash
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i services/inventory.yml services/gitea-only.yml
```

4. For testing connectivity before deploying, you can run:

```bash
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i services/inventory.yml services/synology-gitea-test.yml
```

### Configuration

The Gitea role is configurable through variables in `host_vars/synology1.yml` including:

- Container name and image version
- User and group IDs
- Data directory paths
- HTTP and SSH ports
- Additional environment variables
- Docker labels for integration with tools like Watchtower
