#!/bin/bash
shellcheck disable=SC2154

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Parse command line arguments
COMPONENT=""
COMMAND="plan"
EXTRA_ARGS=""

# Usage function
function show_usage {
  echo "Usage: $0 [component] [command] [extra args]"
  echo ""
  echo "Components:"
  echo "  dns-ha        - High Availability DNS configuration"
  echo "  pihole        - Pi-hole DNS configuration"
  echo "  ups           - UPS monitoring configuration"
  echo ""
  echo "Commands:"
  echo "  plan          - Plan infrastructure changes (default)"
  echo "  apply         - Apply infrastructure changes"
  echo "  destroy       - Destroy infrastructure"
  echo "  output        - Show infrastructure outputs"
  echo "  refresh       - Refresh infrastructure state"
  echo ""
  echo "Examples:"
  echo "  $0 dns-ha plan      - Plan DNS HA infrastructure changes"
  echo "  $0 pihole apply     - Apply Pi-hole infrastructure changes"
  echo "  $0 ups destroy      - Destroy UPS monitoring infrastructure"
  exit 1
}

# Parse arguments
if [[ $# -lt 1 ]]; then
  show_usage
fi

COMPONENT=$1
shift

if [[ $# -gt 0 ]]; then
  COMMAND=$1
  shift
fi

# Additional arguments are passed directly to OpenTofu
EXTRA_ARGS="$*"

# Set the component directory
case $COMPONENT in
  dns-ha)
    COMPONENT_DIR="infrastructure/dns/dns-ha"
    ;;
  pihole)
    COMPONENT_DIR="infrastructure/dns/pihole"
    ;;
  ups|ups-monitoring)
    COMPONENT_DIR="infrastructure/ups-monitoring"
    ;;
  *)
    echo "Error: Unknown component '$COMPONENT'"
    show_usage
    ;;
esac

# Make sure tofu is available
if ! command -v tofu &> /dev/null; then
  echo "Error: OpenTofu (tofu) command not found"
  echo "Please install OpenTofu using: tofuenv install latest && tofuenv use latest"
  exit 1
fi

# Ensure we're running from the repo root
cd "${SCRIPT_DIR}" || exit

echo "Infrastructure Component: $COMPONENT"
echo "Command: $COMMAND"
echo "Working directory: $COMPONENT_DIR"

# Execute the appropriate command
cd "$COMPONENT_DIR" || exit

BACKEND_CONFIG=""
case $COMPONENT in
  dns-ha)
    BACKEND_CONFIG="-backend-config=config.s3.tfbackend"
    ;;
  pihole)
    # Pihole has separate config files for blue/green
    if [[ "$COMMAND" == "plan" || "$COMMAND" == "apply" || "$COMMAND" == "destroy" ]]; then
      echo "For pihole component, please specify blue or green:"
      echo "  ./infra-deploy.sh pihole plan -- -var-file=blue.tfvars -backend-config=blue-config.s3.tfbackend"
      echo "  ./infra-deploy.sh pihole plan -- -var-file=green.tfvars -backend-config=green-config.s3.tfbackend"
      exit 1
    fi
    ;;
esac

# Initialize working directory if needed
if [[ ! -d ".terraform" || "$COMMAND" == "init" ]]; then
  echo "Initializing working directory..."
  if [[ -n "$BACKEND_CONFIG" ]]; then
    tofu init $BACKEND_CONFIG
  else
    tofu init
  fi
fi

# Run the OpenTofu command
case $COMMAND in
  plan)
    # shellcheck disable=SC2086
    tofu plan $EXTRA_ARGS
    ;;
  apply)
    # shellcheck disable=SC2086
    tofu apply $EXTRA_ARGS
    ;;
  destroy)
    # shellcheck disable=SC2086
    tofu destroy $EXTRA_ARGS
    ;;
  output)
    # shellcheck disable=SC2086
    tofu output $EXTRA_ARGS
    ;;
  refresh)
    # shellcheck disable=SC2086
    tofu refresh $EXTRA_ARGS
    ;;
  *)
    echo "Error: Unknown command '$COMMAND'"
    show_usage
    ;;
esac
