#!/bin/bash
# shellcheck disable=SC2154

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ansible --version
ansible-galaxy collection install amazon.aws ansible.utils community.general
ANSIBLE_VERSION=$(ansible --version | grep core | awk '{print $NF}' | sed 's/]//g')
#export PATH=/root/.pkgx/ansible.com/v${ANSIBLE_VERSION}/venv/bin:$PATH
pip install netaddr
