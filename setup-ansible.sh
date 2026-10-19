#!/bin/bash
# shellcheck disable=SC2154
# Fail fast: callers (deploy.sh, services-deploy.sh) go straight into tofu
# apply / ansible-playbook, which fail confusingly on missing dependencies.
set -euo pipefail

ansible --version
ansible-galaxy collection install -r requirements.yml
ANSIBLE_VERSION=$(ansible --version | grep core | awk '{print $NF}' | sed 's/]//g')
# /root/.pkgx/ansible.com/v2.18.6/venv/bin/python.
export PATH=/root/.pkgx/ansible.com/v${ANSIBLE_VERSION}/venv/bin:$PATH
pip install netaddr requests pyyaml
