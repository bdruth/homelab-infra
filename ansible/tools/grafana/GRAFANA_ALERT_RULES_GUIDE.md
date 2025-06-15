# Grafana Alert Rules Technical Guide

## Overview

This document captures the intricate rules and patterns for creating Grafana alert rules programmatically via the REST API. Based on lessons learned from implementing disk monitoring alerts, this guide provides concrete patterns and common pitfalls.

## Table of Contents

- [Alert Rule Structure](#alert-rule-structure)
- [Query Patterns](#query-patterns)
- [Expression Queries](#expression-queries)
- [Common Pitfalls](#common-pitfalls)
- [Working Patterns](#working-patterns)
- [API Guidelines](#api-guidelines)

## Alert Rule Structure

### Basic Structure

```json
{
  "folderUID": "required_folder_uid",
  "title": "Alert Name",
  "condition": "C",  // RefId of the condition query
  "data": [
    // Array of queries (A, B, C, etc.)
  ],
  "noDataState": "NoData|Alerting|OK",
  "execErrState": "Alerting|OK",
  "for": "5m",  // Duration before firing
  "annotations": {
    "description": "Description with {{ $labels.field }} and {{ $values.QueryRef.Value }}",
    "summary": "Summary"
  },
  "labels": {
    "severity": "warning|critical",
    "team": "infrastructure"
  },
  "intervalSeconds": 60
}
```

### Required Fields

- **`folderUID`**: Cannot be empty string - Grafana OSS requires admin permissions
- **`condition`**: Must reference a valid query refId (usually the final threshold query)
- **`data`**: Array of at least one query object
- **`title`**: Unique identifier for the alert rule

### Data States

- **`noDataState`**: 
  - `"NoData"`: Default, shows as "No Data"
  - `"Alerting"`: Triggers alert when no data received (useful for staleness detection)
  - `"OK"`: Treats no data as healthy state

- **`execErrState`**: What to do when query execution fails
  - `"Alerting"`: Trigger alert on query errors (recommended)
  - `"OK"`: Ignore query execution errors

## Query Patterns

### InfluxDB Visual Query Builder Format

```json
{
  "refId": "A",
  "queryType": "",
  "relativeTimeRange": {
    "from": 600,  // Seconds ago
    "to": 0       // Now
  },
  "datasourceUid": "your_influxdb_uid",
  "model": {
    "datasource": {"type": "influxdb", "uid": "your_influxdb_uid"},
    "groupBy": [
      {"params": ["$__interval"], "type": "time"},
      {"params": ["host::tag"], "type": "tag"},
      {"params": ["path::tag"], "type": "tag"},
      {"params": ["null"], "type": "fill"}
    ],
    "measurement": "disk",
    "orderByTime": "ASC",
    "policy": "default",
    "refId": "A",
    "resultFormat": "time_series",
    "select": [
      [
        {"params": ["used_percent"], "type": "field"},
        {"params": [], "type": "mean"}
      ]
    ],
    "tags": [],
    "intervalMs": 1000,
    "maxDataPoints": 43200
  }
}
```

#### Key InfluxDB Query Rules

1. **Time Grouping is Critical**: Always include `{"params": ["$__interval"], "type": "time"}` in `groupBy`
2. **Use Visual Builder**: Don't use `rawQuery: true` for alerts - it causes format issues
3. **Group by Tags**: Include relevant tags like `host::tag`, `path::tag` for proper series identification
4. **Fill Strategy**: Use `{"params": ["null"], "type": "fill"}` to handle missing data
5. **Result Format**: Use `"time_series"` for alerts (not `"table"`)

### InfluxDB Aggregation Functions

```json
"select": [
  [
    {"params": ["field_name"], "type": "field"},
    {"params": [], "type": "mean|last|count|sum|max|min"}
  ]
]
```

Common patterns:
- **`mean`**: Average value over time window
- **`last`**: Most recent value
- **`count`**: Number of data points (useful for staleness detection)
- **`max`**: Peak value in time window

## Expression Queries

### Reduce Expression

Converts time series to single values per series:

```json
{
  "refId": "B",
  "queryType": "",
  "relativeTimeRange": {"from": 0, "to": 0},
  "datasourceUid": "__expr__",
  "model": {
    "datasource": {"type": "__expr__", "uid": "__expr__"},
    "expression": "A",
    "reducer": "last|mean|sum|max|min",
    "settings": {"mode": "dropNN"},
    "type": "reduce",
    "refId": "B",
    "intervalMs": 1000,
    "maxDataPoints": 43200
  }
}
```

#### Reduce Options
- **`last`**: Get the most recent value from time series
- **`mean`**: Average all values in the time series
- **`sum`**: Sum all values (useful for counting)
- **`max`/`min`**: Peak/minimum values
- **`dropNN`**: Drop null/NaN values from calculation

### Threshold Expression

Final condition check:

```json
{
  "refId": "C",
  "queryType": "",
  "relativeTimeRange": {"from": 0, "to": 0},
  "datasourceUid": "__expr__",
  "model": {
    "conditions": [
      {
        "evaluator": {"params": [85], "type": "gt"},
        "operator": {"type": "and"},
        "query": {"params": ["C"]},
        "reducer": {"params": [], "type": "last"},
        "type": "query"
      }
    ],
    "datasource": {"type": "__expr__", "uid": "__expr__"},
    "expression": "B",
    "type": "threshold",
    "refId": "C",
    "intervalMs": 1000,
    "maxDataPoints": 43200
  }
}
```

#### Threshold Operators
- **`gt`**: Greater than
- **`lt`**: Less than
- **`eq`**: Equal to
- **`within_range`**: Between two values
- **`outside_range`**: Outside two values

### Math Expression (Advanced)

For calculations between queries:

```json
{
  "refId": "B",
  "datasourceUid": "__expr__",
  "model": {
    "expression": "$A * 100 / $B",  // Simple math operations only
    "type": "math",
    "refId": "B"
  }
}
```

⚠️ **Math Expression Limitations**:
- No `now()` function available
- Limited to basic arithmetic
- Cannot access InfluxDB functions
- Use InfluxDB math in the query instead when possible

## Common Pitfalls

### 1. Duplicate Labels Error

**Error**: `frame cannot uniquely be identified by its labels: has duplicate results with labels {}`

**Causes**:
- Missing time grouping in InfluxDB query
- Multiple time series with same labels
- Not using reduce expression properly

**Solution**:
```json
// ✅ Correct - includes time grouping
"groupBy": [
  {"params": ["$__interval"], "type": "time"},
  {"params": ["host::tag"], "type": "tag"}
]

// ❌ Wrong - missing time grouping
"groupBy": [
  {"params": ["host::tag"], "type": "tag"}
]
```

### 2. Wrong Data Format Errors

**Error**: `input data must be a wide series but got type long`

**Causes**:
- Using `rawQuery: true` in alert queries
- Using `resultFormat: "table"` instead of `"time_series"`
- Incorrect query structure

**Solution**: Always use visual query builder format with `"time_series"` result format.

### 3. Expression Function Errors

**Error**: `undefined function now()` or `non existent function now`

**Cause**: Trying to use InfluxDB functions in Grafana math expressions.

**Solution**: Use InfluxDB functions in the query itself, not in math expressions.

### 4. Missing Folder UID

**Error**: `folderUID is required`

**Cause**: Empty string or missing `folderUID` field.

**Solution**: Always specify a valid folder UID. Get from `/api/folders` endpoint.

## Working Patterns

### Pattern 1: Threshold Alert (Disk Usage)

3-Query structure: Data → Reduce → Threshold

```json
{
  "condition": "C",
  "data": [
    {
      "refId": "A",
      // InfluxDB query with time grouping
      "model": {
        "groupBy": [
          {"params": ["$__interval"], "type": "time"},
          {"params": ["host::tag"], "type": "tag"},
          {"params": ["path::tag"], "type": "tag"}
        ],
        "select": [
          [{"params": ["used_percent"], "type": "field"}, {"params": [], "type": "mean"}]
        ]
      }
    },
    {
      "refId": "B",
      // Reduce to single value per series
      "model": {
        "expression": "A",
        "reducer": "last",
        "type": "reduce"
      }
    },
    {
      "refId": "C",
      // Threshold check
      "model": {
        "expression": "B",
        "type": "threshold",
        "conditions": [
          {"evaluator": {"params": [85], "type": "gt"}}
        ]
      }
    }
  ]
}
```

### Pattern 2: Data Staleness Alert

3-Query structure: Count → Reduce → Threshold

```json
{
  "condition": "C",
  "noDataState": "Alerting",  // Key for staleness detection
  "data": [
    {
      "refId": "A",
      // Count data points in time window
      "model": {
        "select": [
          [{"params": ["used_percent"], "type": "field"}, {"params": [], "type": "count"}]
        ]
      }
    },
    {
      "refId": "B",
      // Sum counts per host
      "model": {
        "expression": "A",
        "reducer": "sum",
        "type": "reduce"
      }
    },
    {
      "refId": "C",
      // Alert if count < 1 (no data)
      "model": {
        "expression": "B",
        "type": "threshold",
        "conditions": [
          {"evaluator": {"params": [1], "type": "lt"}}
        ]
      }
    }
  ]
}
```

## API Guidelines

### Permissions Requirements

- **Grafana OSS**: Requires Admin role for alert management
- **Grafana Enterprise**: Can use granular RBAC permissions

### Required API Endpoints

1. **Get Folders**: `GET /api/folders` - Required for valid `folderUID`
2. **Get Existing Rules**: `GET /api/v1/provisioning/alert-rules`
3. **Create Rule**: `POST /api/v1/provisioning/alert-rules`
4. **Update Rule**: `PUT /api/v1/provisioning/alert-rules/{uid}`

### Error Handling Best Practices

```python
def create_alert_rule(self):
    # Check permissions first
    folders = self.get_folders()
    if not folders:
        return self.export_alert_config()  # Fallback to manual setup
    
    # Create rule
    response = requests.post(url, json=alert_rule, headers=self.headers)
    
    if response.status_code in [200, 201]:
        return response.json().get('uid')
    else:
        print(f"❌ Failed: {response.status_code}")
        print(f"Response: {response.text}")
        return None
```

### Notification Policies

Use `object_matchers` format (not deprecated `matcher`):

```json
{
  "receiver": "contact-point-name",
  "object_matchers": [
    ["alertname", "=", "Your Alert Name"]
  ],
  "group_by": ["host", "path"],
  "group_wait": "5s",
  "group_interval": "5m",
  "repeat_interval": "1h"
}
```

## Annotations and Labels

### Annotations (Alert Details)

```json
"annotations": {
  "description": "Host {{ $labels.host }} disk {{ $labels.path }} is {{ printf \"%.1f\" $values.B.Value }}% full",
  "summary": "High disk usage on {{ $labels.host }}"
}
```

- Use `$labels.field` for tag values
- Use `$values.QueryRef.Value` for calculated values
- Use `printf` for number formatting

### Labels (Alert Metadata)

```json
"labels": {
  "severity": "warning|critical",
  "team": "infrastructure",
  "alert_type": "threshold|staleness"
}
```

Labels are used for:
- Routing in notification policies
- Grouping related alerts
- Adding metadata for dashboards

## Testing and Validation

### Manual Testing Steps

1. **Create test alert with short evaluation time**: `"for": "10s"`
2. **Use debug evaluation intervals**: `"intervalSeconds": 10`
3. **Test with known failing conditions**
4. **Verify notification routing**
5. **Check alert history in Grafana UI**

### Common Test Scenarios

1. **Threshold crossing**: Verify alert fires when metric exceeds threshold
2. **Data absence**: Test `noDataState: "Alerting"` behavior
3. **Recovery**: Ensure alert resolves when condition clears
4. **Multiple hosts**: Verify proper grouping and individual host alerts

## Conclusion

Creating Grafana alert rules programmatically requires careful attention to query structure, proper use of expressions, and understanding of the alert evaluation engine. The key to success is:

1. Always use the 3-query pattern: Data → Reduce → Threshold
2. Include proper time grouping in InfluxDB queries
3. Use visual query builder format, not raw queries
4. Handle permissions gracefully with fallback options
5. Test thoroughly with short evaluation periods

Following these patterns will help avoid common pitfalls and create reliable alert rules.