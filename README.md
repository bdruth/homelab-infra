# README

Use NIX via Docker to manage

```
docker run -it -v $(pwd):/workdir -w /workdir nixos/nix
# nix-shell
```

`opentofu`, `ansible`, and `netcat-traditional` will be installed automatically by nixOS, via the `shell.nix` configuration.

_*NOTE*_: ci/cd uses [pkgx](https://pkgx.sh) instead of `nix` currently.

## IaC states

1. `dns/dns-ha`
2. `dns/pihole`

Run `tofu [init|plan|apply]` as you would `terraform` commands. The `pihole` folder has a `tofu-ns.sh` script that supports applying the `blue` or `green` state, just run `./tofu-ns.sh [blue|green] <tofu commands>` instead of a straight `tofu` command.

See [deploy.sh](deploy.sh) for more information on how to deploy.

### Configurations

Each state has a `.tfbackend` file that contains the backend configuration for that state's terraform. For `pihole`, there's a blue and a green variant of this configuration. Each state also has a `terraform.tfvars` file with variables that are specific to each state. Once again, `pihole` has a blue and a green variant of this configuration, common configuration is still in a `terraform.tfvars` file.

Example `config.s3.tfbackend`

```
bucket = "<your-bucket-name>" # Name of the S3 bucket
endpoints = {
  s3 = "http://<your-url-to-alt-s3-api-endpoint>:9000" # Minio endpoint
}
key = "<unique-name-of-your-state-file>.tfstate" # Name of the tfstate file
```

- See [dns/dns-ha/README.md](dns/dns-ha/README.md) for an example `.tfvars` file.
- See [dns/pihole/README.md](dns/pihole/README.md) for an example `.tfvars` file.

#### Ansible configuration

Configuration of the pihole is done via restoring a teleporter backup (from a pre-existing pihole). This backup file is pulled from an S3 bucket as well and requires some configuration in `ansible/pihole/vars/main.yml`

Example:

```
---
s3_api_host_ip: <ip-addr-of-s3-api-host>
s3_api_host_name: <fqdn-of-s3-api-host>
s3_api_endpoint_url: "http://{{ s3_api_host_name }}:9000"
s3_teleporter_bucket_name: <bucket-name-containing-teleporter-backup-file>
s3_teleporter_object_name: <teleporter-backup-file-name>

```
