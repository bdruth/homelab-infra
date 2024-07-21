# module "dns_ha_lxc" {
#   source = "../../modules/lxc"
#   lxc_hostname = "dns-ha"
#   lxc_ip_addr = "192.168.7.6"
#   lxc_gw_addr = var.gw_addr
#   lxc_memory = "512"
#   lxc_storage_pool = "local"
# }

locals {
  dns_ip_addrs = [
    data.terraform_remote_state.pihole_blue.outputs.pihole_ip,
    data.terraform_remote_state.pihole_green.outputs.pihole_ip
  ]
}

# resource "null_resource" "install_dnsdist" {
#   triggers = {
#     dnsdist_conf_hash    = filesha256("${path.module}/../../ansible/dnsdist/dnsdist.conf.j2")
#     ansible_conf_hash = filesha256("${path.module}/../../ansible/dnsdist/main.yml")
#     container_change = module.dns_ha_lxc.lxc_id
#     dns_ip_addrs = jsonencode(local.dns_ip_addrs)
#   }

#   provisioner "local-exec" {
#     command     = "until nc -zv ${module.dns_ha_lxc.lxc_ip_addr} 22; do echo 'Waiting for SSH to be available...'; sleep 5; done"
#     working_dir = path.module
#   }
#   provisioner "local-exec" {
#     command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${module.dns_ha_lxc.lxc_ip_addr},' -u root --private-key ${var.ssh_priv_key_path} ../../ansible/dnsdist/main.yml -e '{\"dns_ip_addrs\":${jsonencode(local.dns_ip_addrs)}}'"
#     working_dir = path.module
#   }
# }

# output "dns_ha_ip" {
#   value = module.dns_ha_lxc.lxc_ip_addr
# }
