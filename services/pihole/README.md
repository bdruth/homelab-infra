# Pihole Ansible Playbook

This Ansible playbook installs and configures Pi-hole on a remote host.

## Features

- Installs Pi-hole and necessary dependencies
- Configures Pi-hole with custom DNS records
- Sets up CNAME records for local hosts
- Backups configuration to S3 bucket
- Manages blocklists, allow/deny entries, groups and clients as repo state

## Blocking configuration

Blocklists and allow/deny entries live in `vars/main.yml` and are reconciled into
`gravity.db` on every deploy, identically on blue and green. Edit the vars, not the
web UI — the UI is fine for experimenting, but only what is in `vars/main.yml`
survives a rebuild and stays consistent across both hosts.

| Variable | Purpose |
| --- | --- |
| `pihole_adlists` | Blocklist URLs |
| `pihole_domainlist` | Allow/deny entries (`type`: 0 exact allow, 1 exact deny, 2 regex allow, 3 regex deny) |
| `pihole_domainlist_absent` | Entries to retire, by `(domain, type)` |
| `pihole_groups` / `pihole_clients` | Per-client policy |
| `*_prune` | When true, anything absent from the corresponding var is deleted |

The prune flags default to false so an urgent fix made via the UI survives the next
deploy. The tradeoff is that superseded entries linger, so use
`pihole_domainlist_absent` to retire one deliberately.

Two templates apply this, split by cost: `gravity-config.sql.j2` (groups, clients,
domainlist) only needs `pihole reloadlists`, while `gravity-adlists.sql.j2` forces a
full `pihole -g` rebuild that re-downloads every list and takes minutes. Adding an
adlist row on its own blocks nothing until gravity runs.

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