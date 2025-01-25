module "dns_ha_lxc" {
  source = "../../modules/lxc"
  lxc_hostname = "dns-ha"
  lxc_ip_addr = var.dns_ip_addr
  lxc_gw_addr = var.gw_addr
  lxc_memory = "512"
  lxc_onboot = true
  lxc_hwaddr = "BC:24:11:27:F6:81"
}

locals {
  dns_ip_addrs = [
    data.terraform_remote_state.pihole_blue.outputs.pihole_ip,
    data.terraform_remote_state.pihole_green.outputs.pihole_ip
  ]
}

resource "null_resource" "install_dnsdist" {
  triggers = {
    ansible_changes = sha1(join("", [for f in sort(fileset("${path.module}/../../ansible/dnsdist", "**")): filesha1("${path.module}/../../ansible/dnsdist/${f}")]))
    container_change = module.dns_ha_lxc.lxc_id
    dns_ip_addrs = jsonencode(local.dns_ip_addrs)
  }

  provisioner "local-exec" {
    command     = "until nc -zv ${module.dns_ha_lxc.lxc_ip_addr} 22; do echo 'Waiting for SSH to be available...'; sleep 5; done"
    working_dir = path.module
  }
  provisioner "local-exec" {
    command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${module.dns_ha_lxc.lxc_ip_addr},' -u root --private-key ${var.ssh_priv_key_path} ../../ansible/dnsdist/main.yml -e '{\"dns_ip_addrs\":${jsonencode(local.dns_ip_addrs)}}'"
    working_dir = path.module
  }
}

output "dns_ha_ip" {
  value = module.dns_ha_lxc.lxc_ip_addr
}
