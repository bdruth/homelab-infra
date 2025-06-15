# Disk Monitoring Role

This Ansible role configures disk usage monitoring using Telegraf. It installs Telegraf on target hosts and configures it to collect disk metrics, which are then sent to an InfluxDB instance.

## Integration with Infrastructure

This role is fully integrated with the main infrastructure playbook and can be applied to any host by adding `disk-monitoring` to its `host_roles` list in the inventory.

## Configuration

### Inventory Configuration

Add `disk-monitoring` to the `host_roles` array for any host that needs disk monitoring:

```yaml
my-server:
  ansible_host: 192.168.1.100
  host_roles: [watchtower, disk-monitoring]
  # Optional disk monitoring configuration
  influxdb_url: "http://custom-influxdb:8086"
  influxdb_database: "my_disk_metrics"
```

### Role Variables

The following variables are available for customization:

#### InfluxDB Configuration

| Variable            | Default                            | Description                                      |
| ------------------- | ---------------------------------- | ------------------------------------------------ |
| `influxdb_url`      | `http://influxdb.example.com:8086` | URL of the InfluxDB server                       |
| `influxdb_database` | `disk_monitoring`                  | InfluxDB database name                           |
| `influxdb_username` | ` `                                | InfluxDB username (if authentication is enabled) |
| `influxdb_password` | ` `                                | InfluxDB password (if authentication is enabled) |

#### Telegraf Configuration

| Variable                  | Default | Description                           |
| ------------------------- | ------- | ------------------------------------- |
| `telegraf_interval`       | `60s`   | How often Telegraf collects metrics   |
| `telegraf_flush_interval` | `10s`   | How often Telegraf writes to InfluxDB |

#### Disk Monitoring Configuration

| Variable               | Default                  | Description                              |
| ---------------------- | ------------------------ | ---------------------------------------- |
| `monitor_mount_points` | `[]` (all)               | List of specific mount points to monitor |
| `ignored_mount_points` | `/boot, /boot/efi, etc.` | Mount points to ignore                   |
| `ignored_filesystems`  | `tmpfs, devtmpfs, etc.`  | Filesystem types to ignore               |

## Deployment

### As Part of Infrastructure

Deploy using the main infrastructure playbook:

```bash
ansible-playbook -i inventory.yml infrastructure.yml
```

### Standalone Deployment

To deploy only the disk monitoring role:

```bash
ansible-playbook -i inventory.yml disk-monitoring-only.yml
```

## Grafana Dashboard

A companion tool for creating Grafana dashboards for disk monitoring is available in `ansible/tools/grafana/`. See the [README](../tools/grafana/README.md) in that directory for more information.

## Host-Specific Configuration

Create host-specific variable files in `vars/hostname.yml` to customize settings for individual hosts.
