#!/usr/bin/env bash

set -e

rm -rf .terraform/terraform.tfstate

# Check for minimum of two arguments
if [ $# -lt 2 ]; then
  echo "Usage: $0 <namespace e.g. [blue|green]> <tofu command + args>" >&2
  exit 1
fi

# Set namespace variable from 1st argument
export TF_VAR_namespace=$1
shift
# Verify we have a -config.s3.tfbackend file for this namespace
if [ ! -f "${TF_VAR_namespace}-config.s3.tfbackend" ]; then
  echo "No config file (${TF_VAR_namespace}-config.s3.tfbackend) found for namespace: ${TF_VAR_namespace}" >&2
  exit 1
fi

set -x
tofu init -backend-config="${TF_VAR_namespace}-config.s3.tfbackend" -upgrade  -reconfigure
# tofu taint module.pihole.module.pihole_lxc.proxmox_lxc.container
if [[ "$*" =~ "output" || "$*" =~ "taint" || "$*" =~ "state" ]]
then
  tofu "$@"
else
  tofu "$@" -var-file=<(cat terraform.tfvars "${TF_VAR_namespace}.tfvars")
fi
