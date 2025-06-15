# Grafana Dashboard Tools

This directory contains tools for creating and updating Grafana dashboards and alerts.

## Disk Monitoring Dashboard

The `create-grafana-dashboard.py` script creates a disk monitoring dashboard in Grafana with appropriate alert rules.

### Prerequisites

- Python 3.7+
- Access to a Grafana instance with API permissions
- InfluxDB configured to receive data from Telegraf

### Installation

Install dependencies with:

```bash
cd ansible/tools/grafana
uv sync
```

### Usage

Set required environment variables:

```bash
export GRAFANA_URL="http://your-grafana-host:3000"
export GRAFANA_API_KEY="your-grafana-api-key"
```

Run the script:

```bash
uv run python create-grafana-dashboard.py --with-alerts
```

### Options

- `--grafana-url URL`: Override the Grafana URL (default: uses GRAFANA_URL env var)
- `--api-key KEY`: Override the API key (default: uses GRAFANA_API_KEY env var)
- `--with-alerts`: Create alert rules in addition to the dashboard
- `--help`: Show help message

## Related Ansible Role

This tool complements the `disk-monitoring` Ansible role, which sets up Telegraf to collect disk metrics. To use both together:

1. Add `disk-monitoring` to your host's `host_roles` in your Ansible inventory
2. Run the main infrastructure playbook: `ansible-playbook -i inventory.yml infrastructure.yml`
3. Create/update the Grafana dashboard using this tool
