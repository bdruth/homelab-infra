# Running ansible playbooks manually

1. Launch pkgx in a container -

```
docker run --rm -it \
  --dns <DNS_IP> \ # Useful when running the ansible playbooks for DNS
  -v "<PATH_TO_SSH_KEY>:/root/.ssh/id_rsa" \ # SSH key to use
  -v "$PWD:/opt/app" --workdir=/opt/app \ # mount the workspace into the container
  --env-file .env \ # load secrets from .env file
  pkgxdev/pkgx \ # this is the container we're running
  bash -c 'apt-get update && apt-get install -y dnsutils netcat; \ # container deps to install that aren't in pkgx
    pkgx +tofu +pip +ansible +ssh /bin/bash' # setup pkgx environment
```

2. Setup ansible by running `./setup-ansible.sh` inside the pkgx shell

3. Run ansible playbooks -

```
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ansible/nvidia-gpu/test-inventory.yml ansible/nvidia-gpu/main.yml
```

You may need to use `-i <HOST_IP>,` instead of the test-inventory.yml if one isn't available. Same for specifying the user and private-key, e.g. `-u <user> --private-key <PATH_TO_PRIVATE_KEY>`
