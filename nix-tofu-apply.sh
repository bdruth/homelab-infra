#!/usr/bin/env nix-shell
#! nix-shell -i bash --pure

# shellcheck disable=SC2154
echo "${ansible_pihole_vars_main_yml}" > ansible/pihole/vars/main.yml

cd dns/pihole || exit
./tofu-ns.sh blue plan
./tofu-ns.sh green plan

cd ../dns/dns-ha || exit
tofu init
tofu plan
