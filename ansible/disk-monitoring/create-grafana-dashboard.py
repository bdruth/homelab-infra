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

def main():
    parser = argparse.ArgumentParser(description='Create Grafana dashboard for disk monitoring')
    parser.add_argument('--grafana-url', required=True, help='Grafana URL (e.g., http://grafana.example.com:3000)')
    parser.add_argument('--api-key', required=True, help='Grafana API key with dashboard creation permissions')
    
    args = parser.parse_args()
    
    creator = GrafanaDashboardCreator(args.grafana_url, args.api_key)
    
    try:
        creator.load_ansible_config()
        success = creator.create_dashboard()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()