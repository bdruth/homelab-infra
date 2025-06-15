#!/bin/bash
shellcheck disable=SC2154

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Setup Services environment
"${SCRIPT_DIR}"/setup-services.sh

# Parse command line arguments
PLAYBOOK="services/infrastructure.yml"  # Default playbook
INVENTORY="services/inventory.yml"      # Default inventory
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
      if [[ -f "services/$1.yml" ]]; then
        PLAYBOOK="services/$1.yml"
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
echo "Running Services deployment with playbook: $PLAYBOOK"
echo "Current directory: $(pwd)"
echo "Checking if playbook exists: ls -la $PLAYBOOK"
ls -la "$PLAYBOOK" || echo "Playbook file not found!"

# Ensure we're running from the repo root
cd "${SCRIPT_DIR}" || exit
echo "Working from directory: $(pwd)"

# Debug ansible command
CMD="ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i \"$INVENTORY\" \"$PLAYBOOK\""
if [[ -n "$EXTRA_ARGS" ]]; then
  CMD="$CMD $EXTRA_ARGS"
fi
echo "Running command: $CMD"

# Execute ansible command - removing quotes around EXTRA_ARGS to allow proper expansion
if [[ -z "$EXTRA_ARGS" ]]; then
  ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY" "$PLAYBOOK"
else
  # shellcheck disable=SC2086
  ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY" "$PLAYBOOK" $EXTRA_ARGS
fi
