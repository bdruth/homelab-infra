#!/bin/bash
# Script to create/update Grafana dashboards

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Check for required environment variables
if [[ -z "$GRAFANA_URL" || -z "$GRAFANA_API_KEY" ]]; then
    echo "Error: GRAFANA_URL and GRAFANA_API_KEY environment variables must be set"
    echo ""
    echo "Example:"
    echo "  export GRAFANA_URL=\"http://your-grafana-host:3000\""
    echo "  export GRAFANA_API_KEY=\"your-grafana-api-key\""
    exit 1
fi

# Parse command line arguments
WITH_ALERTS=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --with-alerts)
      WITH_ALERTS=true
      shift
      ;;
    *)
      echo "Unknown option $1"
      echo "Usage: $0 [--with-alerts]"
      echo "  --with-alerts: Create alert rules in addition to the dashboard"
      exit 1
      ;;
  esac
done

set -e

# Setup Python environment and run the dashboard creation script
cd "${SCRIPT_DIR}"
echo "=== Setting up Python environment ==="
uv sync

echo "=== Creating Grafana dashboard ==="
if [[ "$WITH_ALERTS" == true ]]; then
    uv run python create-grafana-dashboard.py \
        --grafana-url "$GRAFANA_URL" \
        --api-key "$GRAFANA_API_KEY" \
        --with-alerts
else
    uv run python create-grafana-dashboard.py \
        --grafana-url "$GRAFANA_URL" \
        --api-key "$GRAFANA_API_KEY"
fi

echo "=== Dashboard creation completed ==="
