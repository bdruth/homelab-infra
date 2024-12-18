#!/bin/bash
# shellcheck disable=SC2154

ansible --version
ansible-galaxy collection install amazon.aws ansible.utils
ANSIBLE_VERSION=$(ansible --version | grep core | awk '{print $NF}' | sed 's/]//g')
export PATH=/root/.pkgx/ansible.com/v${ANSIBLE_VERSION}/venv/bin:$PATH
pip install netaddr


# if [ ! -f ".local" ]; then
#   echo "${ansible_pihole_vars_main_yml}" > ansible/pihole/vars/main.yml
#   echo "${common_tfbackend}" > dns/dns-ha/config.s3.tfbackend
#   echo "${common_tfbackend}" > dns/pihole/blue-config.s3.tfbackend
#   echo "${common_tfbackend}" > dns/pihole/green-config.s3.tfbackend
#   echo "${dnsdist_tfstate_key}" >> dns/dns-ha/config.s3.tfbackend
#   echo "${blue_pihole_tfstate_key}" >> dns/pihole/blue-config.s3.tfbackend
#   echo "${green_pihole_tfstate_key}" >> dns/pihole/green-config.s3.tfbackend
#   echo "${dnsdist_tfvars}" > dns/dns-ha/terraform.tfvars
#   echo "${pihole_blue_tfvars}" > dns/pihole/blue.tfvars
#   echo "${pihole_green_tfvars}" > dns/pihole/green.tfvars
#   echo "${pihole_default_tfvars}" > dns/pihole/terraform.tfvars
#   echo "${dnsdist_ansible_vars}" > ansible/dnsdist/vars/main.yml
# fi

tofu --version

test_dns () {
  set +x
  local DNS_IP="$1";
  # Use dig to look up DNS for api.github.com, on error, loop 5 times and wait 10 seconds between each
  for i in {1..5}; do
    echo -n "Try ($i) of 5 to find DNS for api.github.com ($DNS_IP): "
    # Check provided IP
    if dig api.github.com @"$DNS_IP" +short; then
      # Check default lookup
      echo -n "Try ($i) of 5 to find DNS for api.github.com (default): "
      if dig api.github.com +short; then
        return
      else
        sleep 10
      fi
    else
      sleep 10
    fi
  done
  echo "DNS Test Failed for $DNS_IP"
  exit 1
}

set -e
cd dns/pihole
./tofu-ns.sh blue apply --auto-approve
test_dns "$(./tofu-ns.sh blue output -raw pihole_ip | tail -n 1)"
./tofu-ns.sh green apply --auto-approve
test_dns "$(./tofu-ns.sh green output -raw pihole_ip | tail -n 1)"

cd ../dns-ha
set -x
tofu init -backend-config=config.s3.tfbackend -upgrade -reconfigure
# tofu plan
tofu apply --auto-approve
test_dns "$(tofu output -raw dns_ha_ip | tail -n 1)"
