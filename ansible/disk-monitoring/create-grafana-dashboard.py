#!/usr/bin/env python3
"""
Create Grafana dashboard for disk monitoring.
Reads configuration from Ansible files and creates a disk usage visualization dashboard.
"""

import json
import yaml
import requests
import argparse
import sys
from pathlib import Path

class GrafanaDashboardCreator:
    def __init__(self, grafana_url, api_key):
        self.grafana_url = grafana_url.rstrip('/')
        self.api_key = api_key
        self.headers = {
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json'
        }
        
    def load_ansible_config(self):
        """Load configuration from Ansible files."""
        # Load group vars
        group_vars_path = Path(__file__).parent / 'group_vars' / 'all.yml'
        with open(group_vars_path, 'r') as f:
            self.config = yaml.safe_load(f)
            
        # Load inventory to get host list
        inventory_path = Path(__file__).parent / 'host-inventory.yml'
        with open(inventory_path, 'r') as f:
            inventory = yaml.safe_load(f)
            self.hosts = list(inventory['all']['hosts'].keys())
            
        print(f"Loaded config for database: {self.config['influxdb_database']}")
        print(f"Found {len(self.hosts)} hosts: {', '.join(self.hosts)}")
        
    def create_dashboard_json(self):
        """Create the dashboard JSON configuration."""
        dashboard = {
            "dashboard": {
                "id": None,
                "title": "Disk Monitoring",
                "tags": ["disk", "monitoring", "telegraf"],
                "timezone": "browser",
                "refresh": "30s",
                "time": {
                    "from": "now-1h",
                    "to": "now"
                },
                "timepicker": {
                    "refresh_intervals": ["5s", "10s", "30s", "1m", "5m", "15m", "30m", "1h", "2h", "1d"]
                },
                "templating": {
                    "list": []
                },
                "panels": []
            },
            "overwrite": True
        }
        
        # Create a section for each host (2 rows of 3 hosts each)
        panel_id = 1
        y_position = 0
        
        for i, host in enumerate(self.hosts):
            # Calculate grid position (3 hosts per row)
            row = i // 3
            col = i % 3
            x_position = col * 8  # Each host section is 8 units wide
            y_position = row * 12  # Each row is 12 units high
            
            # Host title/header panel
            dashboard["dashboard"]["panels"].append({
                "id": panel_id,
                "title": "",
                "type": "text",
                "gridPos": {"h": 2, "w": 8, "x": x_position, "y": y_position},
                "options": {
                    "content": f"**{host.replace('.cusack-ruth.name', '')}**",
                    "mode": "markdown"
                }
            })
            panel_id += 1
            
            # Disk usage gauge for this host
            dashboard["dashboard"]["panels"].append({
                "id": panel_id,
                "title": "Disk Usage",
                "type": "gauge",
                "targets": [{
                    "datasource": {"type": "influxdb", "uid": "denl7c5ccxam8a"},
                    "groupBy": [
                        {"params": ["path"], "type": "tag"}
                    ],
                    "measurement": "disk",
                    "orderByTime": "ASC",
                    "policy": "default",
                    "refId": "A",
                    "resultFormat": "time_series",
                    "select": [
                        [{"params": ["used_percent"], "type": "field"}, {"params": [], "type": "last"}, {"params": ["usage"], "type": "alias"}]
                    ],
                    "tags": [
                        {"key": "host", "operator": "=", "value": host}
                    ],
                    "adhocFilters": []
                }],
                "gridPos": {"h": 4, "w": 8, "x": x_position, "y": y_position + 2},
                "options": {
                    "orientation": "auto",
                    "reduceOptions": {
                        "values": False,
                        "calcs": ["lastNotNull"],
                        "fields": ""
                    },
                    "showThresholdLabels": False,
                    "showThresholdMarkers": True
                },
                "fieldConfig": {
                    "defaults": {
                        "color": {"mode": "thresholds"},
                        "mappings": [],
                        "thresholds": {
                            "steps": [
                                {"color": "green", "value": None},
                                {"color": "yellow", "value": 70},
                                {"color": "orange", "value": 80},
                                {"color": "red", "value": self.config.get('disk_usage_threshold', 85)}
                            ]
                        },
                        "unit": "percent",
                        "max": 100,
                        "min": 0
                    },
                    "overrides": [
                        {
                            "matcher": {"id": "byRegexp", "options": ".*"},
                            "properties": [
                                {"id": "displayName", "value": "${__field.labels.path}"}
                            ]
                        }
                    ]
                }
            })
            panel_id += 1
            
            # Disk details table for this host
            dashboard["dashboard"]["panels"].append({
                "id": panel_id,
                "title": "Disk Details",
                "type": "table",
                "targets": [{
                    "datasource": {"type": "influxdb", "uid": "denl7c5ccxam8a"},
                    "groupBy": [
                        {"params": ["path"], "type": "tag"}
                    ],
                    "measurement": "disk",
                    "orderByTime": "ASC",
                    "policy": "default",
                    "refId": "A",
                    "resultFormat": "table",
                    "select": [
                        [{"params": ["used_percent"], "type": "field"}, {"params": [], "type": "last"}],
                        [{"params": ["free"], "type": "field"}, {"params": [], "type": "last"}, {"params": [" / 1073741824"], "type": "math"}, {"params": ["free_gb"], "type": "alias"}],
                        [{"params": ["total"], "type": "field"}, {"params": [], "type": "last"}, {"params": [" / 1073741824"], "type": "math"}, {"params": ["total_gb"], "type": "alias"}]
                    ],
                    "tags": [
                        {"key": "host", "operator": "=", "value": host}
                    ],
                    "adhocFilters": []
                }],
                "gridPos": {"h": 6, "w": 8, "x": x_position, "y": y_position + 6},
                "fieldConfig": {
                    "defaults": {
                        "color": {"mode": "thresholds"},
                        "custom": {
                            "align": "auto",
                            "cellOptions": {"type": "auto"},
                            "inspect": False
                        },
                        "mappings": [],
                        "thresholds": {
                            "steps": [
                                {"color": "green", "value": None},
                                {"color": "red", "value": 80}
                            ]
                        }
                    },
                    "overrides": [
                        {
                            "matcher": {"id": "byName", "options": "Time"},
                            "properties": [
                                {"id": "custom.hidden", "value": True}
                            ]
                        },
                        {
                            "matcher": {"id": "byName", "options": "path"},
                            "properties": [
                                {"id": "displayName", "value": "Mount Point"},
                                {"id": "custom.width", "value": 120}
                            ]
                        },
                        {
                            "matcher": {"id": "byName", "options": "used_percent"},
                            "properties": [
                                {"id": "displayName", "value": "Used (%)"},
                                {"id": "unit", "value": "percent"},
                                {"id": "custom.cellOptions", "value": {"type": "color-background"}},
                                {"id": "thresholds", "value": {
                                    "steps": [
                                        {"color": "green", "value": None},
                                        {"color": "yellow", "value": 70},
                                        {"color": "red", "value": self.config.get('disk_usage_threshold', 85)}
                                    ]
                                }},
                                {"id": "max", "value": 100},
                                {"id": "min", "value": 0},
                                {"id": "custom.width", "value": 80}
                            ]
                        },
                        {
                            "matcher": {"id": "byName", "options": "free_gb"},
                            "properties": [
                                {"id": "displayName", "value": "Free (GB)"},
                                {"id": "unit", "value": "decgbytes"},
                                {"id": "decimals", "value": 1},
                                {"id": "custom.width", "value": 100}
                            ]
                        },
                        {
                            "matcher": {"id": "byName", "options": "total_gb"},
                            "properties": [
                                {"id": "displayName", "value": "Total (GB)"},
                                {"id": "unit", "value": "decgbytes"},
                                {"id": "decimals", "value": 1},
                                {"id": "custom.width", "value": 100}
                            ]
                        }
                    ]
                }
            })
            panel_id += 1
        
        return dashboard
        
    def get_existing_alert_rules(self):
        """Get existing alert rules to understand the structure."""
        url = f"{self.grafana_url}/api/v1/provisioning/alert-rules"
        response = requests.get(url, headers=self.headers)
        
        if response.status_code == 200:
            rules = response.json()
            print(f"Found {len(rules)} existing alert rules")
            if rules:
                print("Example rule structure:")
                print(json.dumps(rules[0], indent=2))
            return rules
        else:
            print(f"❌ Failed to get existing alert rules: {response.status_code}")
            print(f"   Response: {response.text}")
            return []

    def get_folders(self):
        """Get available folders for alert rules."""
        url = f"{self.grafana_url}/api/folders"
        response = requests.get(url, headers=self.headers)
        
        if response.status_code == 200:
            return response.json()
        else:
            print(f"❌ Failed to get folders: {response.status_code}")
            return []

    def create_alert_rule(self):
        """Create alert rule for disk usage threshold."""
        threshold = self.config.get('disk_usage_threshold', 85)
        
        # Get available folders
        folders = self.get_folders()
        folder_uid = ""
        
        # Try to find a suitable folder or use the first one
        if folders:
            # Look for a monitoring/alerting folder, or use the first available
            for folder in folders:
                if any(keyword in folder['title'].lower() for keyword in ['monitor', 'alert', 'disk']):
                    folder_uid = folder['uid']
                    break
            
            if not folder_uid:
                folder_uid = folders[0]['uid']
        
        # Try with minimal required fields first
        alert_rule = {
            "folderUID": folder_uid,
            "title": "Disk Usage Alert",
            "condition": "B",
            "data": [
                {
                    "refId": "A",
                    "queryType": "",
                    "relativeTimeRange": {
                        "from": 600,
                        "to": 0
                    },
                    "datasourceUid": "denl7c5ccxam8a",
                    "model": {
                        "measurement": "disk",
                        "select": [
                            [{"params": ["used_percent"], "type": "field"}, {"params": [], "type": "last"}]
                        ],
                        "groupBy": [
                            {"params": ["host"], "type": "tag"},
                            {"params": ["path"], "type": "tag"}
                        ],
                        "tags": [],
                        "refId": "A"
                    }
                },
                {
                    "refId": "B", 
                    "queryType": "",
                    "relativeTimeRange": {
                        "from": 0,
                        "to": 0
                    },
                    "datasourceUid": "__expr__",
                    "model": {
                        "type": "threshold",
                        "expression": f"A > {threshold}",
                        "refId": "B"
                    }
                }
            ],
            "noDataState": "NoData",
            "execErrState": "Alerting",
            "for": "5m",
            "annotations": {
                "description": f"Disk usage exceeded {threshold}%",
                "summary": "High disk usage detected"
            },
            "labels": {},
            "intervalSeconds": 60
        }
        
        # Create the alert rule
        url = f"{self.grafana_url}/api/v1/provisioning/alert-rules"
        response = requests.post(url, json=alert_rule, headers=self.headers)
        
        if response.status_code in [200, 201]:
            result = response.json()
            print(f"✅ Alert rule created successfully!")
            return result.get('uid', '')
        else:
            print(f"❌ Failed to create alert rule: {response.status_code}")
            print(f"   Response: {response.text}")
            return None

    def create_notification_policy(self, alert_rule_uid):
        """Create notification policy to route alerts to Pushover."""
        # First, get existing notification policies
        url = f"{self.grafana_url}/api/v1/provisioning/policies"
        response = requests.get(url, headers=self.headers)
        
        if response.status_code != 200:
            print(f"❌ Failed to get existing policies: {response.status_code}")
            return False
            
        existing_policy = response.json()
        
        # Add our disk monitoring policy as a nested policy
        disk_policy = {
            "receiver": "autogen-contact-point-default",
            "object_matchers": [
                [
                    "alertname",
                    "=",
                    "Disk Usage Alert"
                ]
            ],
            "continue": False,
            "group_by": ["host", "path"],
            "group_wait": "5s",
            "group_interval": "5m",
            "repeat_interval": "1h"
        }
        
        # Add to existing nested policies or create new list
        if "routes" not in existing_policy:
            existing_policy["routes"] = []
        existing_policy["routes"].append(disk_policy)
        
        # Update the notification policy
        response = requests.put(url, json=existing_policy, headers=self.headers)
        
        if response.status_code == 202:
            print(f"✅ Notification policy updated successfully!")
            return True
        else:
            print(f"❌ Failed to update notification policy: {response.status_code}")
            print(f"   Response: {response.text}")
            return False

    def create_dashboard(self):
        """Create the dashboard in Grafana."""
        dashboard_json = self.create_dashboard_json()
        
        url = f"{self.grafana_url}/api/dashboards/db"
        response = requests.post(url, json=dashboard_json, headers=self.headers)
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Dashboard created successfully!")
            print(f"   Dashboard URL: {self.grafana_url}/d/{result['uid']}")
        else:
            print(f"❌ Failed to create dashboard: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
        return True

    def export_alert_config(self):
        """Export alert rule configuration for manual import."""
        threshold = self.config.get('disk_usage_threshold', 85)
        
        # Create alert rule configuration
        alert_rule = {
            "folderUID": "",
            "title": "Disk Usage Alert",
            "condition": "B",
            "data": [
                {
                    "refId": "A",
                    "queryType": "",
                    "relativeTimeRange": {
                        "from": 600,
                        "to": 0
                    },
                    "datasourceUid": "denl7c5ccxam8a",
                    "model": {
                        "datasource": {"type": "influxdb", "uid": "denl7c5ccxam8a"},
                        "measurement": "disk",
                        "select": [
                            [{"params": ["used_percent"], "type": "field"}, {"params": [], "type": "last"}]
                        ],
                        "groupBy": [
                            {"params": ["host"], "type": "tag"},
                            {"params": ["path"], "type": "tag"}
                        ],
                        "tags": [],
                        "refId": "A"
                    }
                },
                {
                    "refId": "B",
                    "queryType": "",
                    "relativeTimeRange": {
                        "from": 0,
                        "to": 0
                    },
                    "datasourceUid": "__expr__",
                    "model": {
                        "type": "threshold",
                        "expression": f"A > {threshold}",
                        "refId": "B"
                    }
                }
            ],
            "noDataState": "NoData",
            "execErrState": "Alerting",
            "for": "5m",
            "annotations": {
                "description": f"Disk usage on {{{{ $labels.host }}}}:{{{{ $labels.path }}}} is {{{{ $value }}}}% which exceeds the threshold of {threshold}%",
                "summary": "High disk usage detected on {{ $labels.host }}"
            },
            "labels": {
                "severity": "warning",
                "team": "infrastructure"
            },
            "intervalSeconds": 60
        }
        
        # Export to file
        alert_file = "disk-usage-alert-rule.json"
        with open(alert_file, 'w') as f:
            json.dump(alert_rule, f, indent=2)
        
        # Create notification policy update
        notification_policy = {
            "receiver": "autogen-contact-point-default",
            "object_matchers": [
                ["alertname", "=", "Disk Usage Alert"]
            ],
            "continue": False,
            "group_by": ["host", "path"],
            "group_wait": "5s",
            "group_interval": "5m",
            "repeat_interval": "1h"
        }
        
        policy_file = "disk-usage-notification-policy.json"
        with open(policy_file, 'w') as f:
            json.dump(notification_policy, f, indent=2)
        
        print(f"✅ Alert configuration exported to {alert_file}")
        print(f"✅ Notification policy exported to {policy_file}")
        print()
        print("📋 Manual Setup Instructions:")
        print("1. Create API key with alert permissions:")
        print("   - Go to Grafana → Configuration → API Keys")
        print("   - Create key with 'Admin' role or specific alert permissions:")
        print("     • alert.rules:read, alert.rules:write, folders:read")
        print()
        print("2. Import alert rule:")
        print(f"   curl -X POST {self.grafana_url}/api/v1/provisioning/alert-rules \\\\")
        print("        -H 'Authorization: Bearer YOUR_ALERT_API_KEY' \\\\")
        print("        -H 'Content-Type: application/json' \\\\")
        print(f"        -d @{alert_file}")
        print()
        print("3. Update notification policy:")
        print("   - Go to Grafana → Alerting → Notification policies")
        print("   - Add a nested route with:")
        print("     • Matcher: alertname = Disk Usage Alert")
        print("     • Contact point: autogen-contact-point-default")
        print("     • Group by: host, path")
        print("     • Timing: 5s wait, 5m interval, 1h repeat")
        
        return True

    def create_alerting(self):
        """Create alert rule and notification policy."""
        print("Creating alert rule...")
        alert_rule_uid = self.create_alert_rule()
        if alert_rule_uid is None:
            print("❌ Alert creation failed due to permissions.")
            print("🔄 Falling back to export mode...")
            return self.export_alert_config()
            
        print("Updating notification policy...")
        return self.create_notification_policy(alert_rule_uid)

def main():
    parser = argparse.ArgumentParser(description='Create Grafana dashboard for disk monitoring')
    parser.add_argument('--grafana-url', required=True, help='Grafana URL (e.g., http://grafana.example.com:3000)')
    parser.add_argument('--api-key', required=True, help='Grafana API key with dashboard creation permissions')
    parser.add_argument('--with-alerts', action='store_true', help='Also create alert rules and notification policies')
    parser.add_argument('--debug-alerts', action='store_true', help='Just examine existing alert rules and policies')
    
    args = parser.parse_args()
    
    creator = GrafanaDashboardCreator(args.grafana_url, args.api_key)
    
    try:
        creator.load_ansible_config()
        
        # Debug mode - just examine existing rules
        if args.debug_alerts:
            print("=== Existing Alert Rules ===")
            creator.get_existing_alert_rules()
            print("\n=== Existing Notification Policies ===")
            url = f"{creator.grafana_url}/api/v1/provisioning/policies"
            response = requests.get(url, headers=creator.headers)
            if response.status_code == 200:
                print(json.dumps(response.json(), indent=2))
            else:
                print(f"Failed to get policies: {response.status_code}")
            sys.exit(0)
        
        # Create dashboard
        dashboard_success = creator.create_dashboard()
        if not dashboard_success:
            sys.exit(1)
            
        # Create alerting if requested
        if args.with_alerts:
            alerting_success = creator.create_alerting()
            if not alerting_success:
                print("⚠️  Dashboard created but alerting setup failed")
                sys.exit(1)
                
        sys.exit(0)
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()