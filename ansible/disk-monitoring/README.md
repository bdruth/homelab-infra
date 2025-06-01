# Disk Monitoring with Telegraf and Grafana

This Ansible playbook configures disk monitoring across homelab infrastructure using Telegraf to collect disk metrics and send them to InfluxDB, with Grafana dashboard and alerting capabilities.

## Overview

The system monitors disk usage and I/O metrics across multiple hosts and provides:
- Real-time disk usage visualization in Grafana
- Automated alerting when disk usage exceeds configurable thresholds
- Pushover notifications for alerts
- Support for multiple filesystem types and mount points

## Architecture

```
Hosts (Telegraf) → InfluxDB → Grafana Dashboard + Alerts → Pushover
```

## Files

- `main.yml` - Main Ansible playbook for configuring Telegraf
- `test-playbook.yml` - Validation tests for the monitoring setup
- `telegraf-disk.conf.j2` - Telegraf configuration template
- `group_vars/all.yml` - Default configuration variables
- `host_vars/` - Host-specific variable overrides
- `host-inventory.yml` - Inventory of monitored hosts
- `create-grafana-dashboard.py` - Python script to create Grafana dashboard and alerts
- `pyproject.toml` - Python dependencies for dashboard creation

## Prerequisites

- InfluxDB instance running and accessible
- Grafana instance with InfluxDB datasource configured
- Python 3.13+ with `uv` package manager
- Ansible installed on control machine

## Configuration

### Variables (group_vars/all.yml)

```yaml
# InfluxDB connection
influxdb_host: "your-influxdb-host.example.com"
influxdb_port: 8086
influxdb_database: "disk_monitoring"

# Monitoring settings
disk_usage_threshold: 85  # Alert threshold percentage
telegraf_interval: "60s"  # Collection interval

# Alert timing
alert_eval_for: "5m"      # How long condition must be true
alert_interval_seconds: 60 # Evaluation frequency
```

### Host-specific Configuration

Host-specific settings are stored in encrypted files under `host_vars/`. These files can override default settings such as:

```yaml
# Example host-specific configuration
monitor_mount_points:
  - "/home"
  - "/var/log"
```

## Installation

### 1. Deploy Telegraf Configuration

```bash
# Run on all hosts
ansible-playbook -i host-inventory.yml main.yml

# Run on specific host
ansible-playbook -i host-inventory.yml main.yml --limit hostname
```

### 2. Validate Installation

```bash
# Test the monitoring setup
ansible-playbook -i host-inventory.yml test-playbook.yml
```

### 3. Create Grafana Dashboard and Alerts

Install Python dependencies:
```bash
uv sync
```

Create dashboard with alerting:
```bash
uv run python create-grafana-dashboard.py \
  --grafana-url http://grafana.example.com:3000 \
  --api-key YOUR_GRAFANA_API_KEY \
  --with-alerts
```

For dashboard only:
```bash
uv run python create-grafana-dashboard.py \
  --grafana-url http://grafana.example.com:3000 \
  --api-key YOUR_GRAFANA_API_KEY
```

## Features

### Monitoring

- **Disk Usage**: Monitors used space percentage per mount point
- **Disk I/O**: Tracks read/write operations and throughput
- **Filesystem Filtering**: Ignores temporary filesystems (tmpfs, devtmpfs, etc.)
- **Custom Mount Points**: Configure specific paths to monitor per host

### Dashboard

- **Multi-host View**: Grid layout showing all monitored hosts
- **Real-time Gauges**: Visual disk usage indicators with color-coded thresholds
- **Detailed Tables**: Shows mount points, usage percentages, and free space
- **Auto-refresh**: Updates every 30 seconds

### Alerting

- **Threshold Alerts**: Configurable disk usage percentage alerts
- **Smart Grouping**: Groups alerts by host and mount point
- **Pushover Integration**: Mobile notifications with custom templates
- **Rate Limiting**: Prevents alert spam with configurable intervals

## Monitoring Hosts

The inventory includes multiple hosts across your homelab infrastructure. Specific hostnames are defined in the encrypted `host-inventory.yml` file.

## Troubleshooting

### Check Telegraf Status
```bash
ansible all -i host-inventory.yml -m shell -a "systemctl status telegraf" --become
```

### Validate Configuration
```bash
ansible all -i host-inventory.yml -m shell -a "telegraf --config /etc/telegraf/telegraf.d/disk.conf --test" --become
```

### Test InfluxDB Connectivity
```bash
ansible all -i host-inventory.yml -m uri -a "url=http://your-influxdb-host:8086/ping method=GET"
```

### Query Metrics Manually
```bash
curl -G 'http://your-influxdb-host:8086/query' \
  --data-urlencode "db=disk_monitoring" \
  --data-urlencode "q=SELECT * FROM disk WHERE host='hostname' ORDER BY time DESC LIMIT 10"
```

## Alert Configuration

### Grafana API Permissions

For alert management, the API key needs Admin role or specific permissions:
- `alert.rules:read`
- `alert.rules:write` 
- `folders:read`

### Manual Alert Setup

If API permissions are insufficient, the script exports configuration files:
- `disk-usage-alert-rule.json` - Alert rule configuration
- `disk-usage-notification-policy.json` - Notification routing

Import these manually in Grafana UI under Alerting section.

## Maintenance

### Update Thresholds
1. Modify `disk_usage_threshold` in `group_vars/all.yml`
2. Re-run playbook: `ansible-playbook -i host-inventory.yml main.yml`
3. Update Grafana alerts: `uv run python create-grafana-dashboard.py --with-alerts ...`

### Add New Hosts
1. Add host to `host-inventory.yml`
2. Create `host_vars/hostname.yml` if needed
3. Run playbook on new host: `ansible-playbook -i host-inventory.yml main.yml --limit new-hostname`
4. Recreate dashboard to include new host: `uv run python create-grafana-dashboard.py ...`

## Security

This repository uses `git-crypt` to encrypt sensitive configuration files. The following file patterns are encrypted:
- `*-inventory.yml` - Host inventory files
- `**/group_vars/*.yml` - Group variable files  
- `**/host_vars/*.yml` - Host-specific variable files

These encrypted files contain sensitive information like hostnames, IP addresses, and other infrastructure details.

## Development

The Python dashboard creation script uses:
- `pyyaml` for reading Ansible configuration
- `requests` for Grafana API interactions
- Grafana's provisioning API for programmatic management

Run with `uv` for dependency management:
```bash
uv add pyyaml requests  # Add new dependencies
uv run python create-grafana-dashboard.py --help
```