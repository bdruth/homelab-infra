#!/bin/bash
# shellcheck disable=SC2154

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
REPO_ROOT="${SCRIPT_DIR}/../.."

# Parse command line arguments
DEPLOY_ANSIBLE=false
DEPLOY_GRAFANA=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --ansible)
      DEPLOY_ANSIBLE=true
      shift
      ;;
    --grafana)
      DEPLOY_GRAFANA=true
      shift
      ;;
    --all)
      DEPLOY_ANSIBLE=true
      DEPLOY_GRAFANA=true
      shift
      ;;
    *)
      echo "Unknown option $1"
      echo "Usage: $0 [--ansible] [--grafana] [--all]"
      echo "  --ansible: Deploy Telegraf configuration via Ansible"
      echo "  --grafana: Update Grafana dashboard and alerts"
      echo "  --all: Deploy both Ansible and Grafana components"
      exit 1
      ;;
  esac
done

# If no specific options provided, deploy all
if [[ "$DEPLOY_ANSIBLE" == false && "$DEPLOY_GRAFANA" == false ]]; then
  DEPLOY_ANSIBLE=true
  DEPLOY_GRAFANA=true
fi

set -e

if [[ "$DEPLOY_ANSIBLE" == true ]]; then
  echo "=== Setting up Ansible environment ==="
  "${REPO_ROOT}"/setup-ansible.sh

  echo "=== Deploying disk monitoring via Ansible ==="
  cd "${SCRIPT_DIR}"
  
  echo "Running main playbook with validation tests..."
  ansible-playbook -i host-inventory.yml test-playbook.yml
fi

if [[ "$DEPLOY_GRAFANA" == true ]]; then
  echo "=== Updating Grafana dashboard and alerts ==="
  cd "${SCRIPT_DIR}"
  
  # Check if required environment variables are set
  if [[ -z "$GRAFANA_URL" || -z "$GRAFANA_API_KEY" ]]; then
    echo "Error: GRAFANA_URL and GRAFANA_API_KEY environment variables must be set"
    exit 1
  fi

  echo "Creating Grafana dashboard and alerts..."
  uv sync
  uv run python create-grafana-dashboard.py \
    --grafana-url "$GRAFANA_URL" \
    --api-key "$GRAFANA_API_KEY" \
    --with-alerts
fi

echo "=== Disk monitoring deployment completed ==="
