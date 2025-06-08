#!/bin/bash
# shellcheck disable=SC2154

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Setup Ansible environment
"${SCRIPT_DIR}"/setup-ansible.sh

# Parse command line arguments
PLAYBOOK="ansible/infrastructure.yml"  # Default playbook
INVENTORY="ansible/inventory.yml"      # Default inventory
EXTRA_ARGS=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --playbook=*)
      PLAYBOOK="${1#*=}"
      shift
      ;;
    --inventory=*)
      INVENTORY="${1#*=}"
      shift
      ;;
    --*)
      EXTRA_ARGS="$EXTRA_ARGS $1"
      shift
      ;;
    *)
      # If a non-option argument is provided, assume it's a specific playbook
      if [[ -f "ansible/$1.yml" ]]; then
        PLAYBOOK="ansible/$1.yml"
      elif [[ -f "$1" ]]; then
        PLAYBOOK="$1"
      else
        echo "Warning: Unknown parameter or playbook '$1'"
      fi
      shift
      ;;
  esac
done

# Run Ansible playbook
echo "Running Ansible deployment with playbook: $PLAYBOOK"
echo "Current directory: $(pwd)"
echo "Checking if playbook exists: ls -la $PLAYBOOK"
ls -la "$PLAYBOOK" || echo "Playbook file not found!"

# Ensure we're running from the repo root
cd "${SCRIPT_DIR}" || exit
echo "Working from directory: $(pwd)"

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY" "$PLAYBOOK" "$EXTRA_ARGS"
