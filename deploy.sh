#!/bin/bash
# shellcheck disable=SC2154

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ansible --version
ansible-galaxy collection install amazon.aws ansible.utils
ANSIBLE_VERSION=$(ansible --version | grep core | awk '{print $NF}' | sed 's/]//g')
export PATH=/root/.pkgx/ansible.com/v${ANSIBLE_VERSION}/venv/bin:$PATH
pip install netaddr

tofu --version

test_dns () {
  set +x
  local DNS_IP="$1";
  local host="$2";
  # Use dig to look up DNS for api.github.com, on error, loop 5 times and wait 10 seconds between each
  for i in {1..5}; do
    echo -n "Try ($i) of 5 to find DNS for $host ($DNS_IP): "
    # Check provided IP
    if dig "$host" @"$DNS_IP" +short; then
      # Check default lookup
      echo -n "Try ($i) of 5 to find DNS for $host (default): "
      if dig "$host" +short; then
        return
      else
        sleep 10
      fi
    else
      sleep 10
    fi
  done
  echo "DNS Test Failed to retrieve $host for $DNS_IP"
  exit 1
}

set -e
cd "${SCRIPT_DIR}/dns/pihole"
./tofu-ns.sh blue apply --auto-approve
pihole_blue_ip=$(./tofu-ns.sh blue output -raw pihole_ip | tail -n 1)
test_dns "$pihole_blue_ip" "api.github.com"
./tofu-ns.sh green apply --auto-approve
pihole_green_ip=$(./tofu-ns.sh green output -raw pihole_ip | tail -n 1)
test_dns "$pihole_green_ip" "api.github.com"

cd "${SCRIPT_DIR}/dns/dns-ha"
set -x
tofu init -backend-config=config.s3.tfbackend -upgrade -reconfigure
# tofu plan
tofu apply --auto-approve
dns_ha_ip=$(tofu output -raw dns_ha_ip | tail -n 1)
test_dns "$dns_ha_ip" "api.github.com"
