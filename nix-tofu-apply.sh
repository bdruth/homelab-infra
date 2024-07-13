#!/usr/bin/env nix-shell
#! nix-shell -i bash --pure

# shellcheck disable=SC2154
echo "${ansible_pihole_vars_main_yml}" > ansible/pihole/vars/main.yml
echo "${common_tfbackend}" > dns/dns-ha/config.s3.tfbackend
echo "${common_tfbackend}" > dns/pihole/blue-config.s3.tfbackend
echo "${common_tfbackend}" > dns/pihole/green-config.s3.tfbackend
echo "${dnsdist_tfstate_key}" >> dns/dns-ha/config.s3.tfbackend
echo "${blue_pihole_tfstate_key}" >> dns/pihole/blue-config.s3.tfbackend
echo "${green_pihole_tfstate_key}" >> dns/pihole/green-config.s3.tfbackend
echo "${dnsdist_tfvars}" > dns/dns-ha/terraform.tfvars
echo "${pihole_blue_tfvars}" > dns/pihole/blue.tfvars
echo "${pihole_green_tfvars}" > dns/pihole/green.tfvars
echo "${pihole_default_tfvars}" > dns/pihole/terraform.tfvars

cd dns/pihole || exit
./tofu-ns.sh blue plan
./tofu-ns.sh green plan

cd ../dns/dns-ha || exit
tofu init
tofu plan
