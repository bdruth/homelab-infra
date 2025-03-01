# Pihole Ansible Playbook

This Ansible playbook installs and configures Pi-hole on a remote host.

## Features

- Installs Pi-hole and necessary dependencies
- Configures Pi-hole with custom DNS records
- Sets up CNAME records for local hosts
- Backups configuration to S3 bucket

## Changes

- Updated to support Pi-hole v6.0+ by switching from generating custom.list to writing directly to pihole.toml hosts array
- CNAME records are now directly generated in the pihole.toml cnameRecords array
- Maintains all other Pi-hole configuration settings

## Testing

To test the template generation locally:

```bash
cd ansible/pihole
docker-compose -f test-docker-compose.yml up
```

This will run a test that renders the pihole.toml.j2 template with the current DNS and CNAME records.