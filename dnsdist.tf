module "dns_ha_lxc" {
  source = "./modules/lxc"
  lxc_hostname = "dns-ha"
  lxc_ip_addr = "192.168.7.3"
  lxc_gw_addr = "192.168.7.1"
  lxc_memory = "512"
}

resource "null_resource" "install_dnsdist" {
  triggers = {
    dnsdist_conf_hash    = filesha256("${path.module}/ansible/dnsdist/dnsdist.conf.j2")
    ansible_conf_hash = filesha256("${path.module}/ansible/dnsdist/main.yml")
    container_change = module.dns_ha_lxc.lxc_id
    dns_ip_addrs = jsonencode(local.dns_ip_addrs)
  }

  provisioner "local-exec" {
    command     = "until nc -zv ${module.dns_ha_lxc.lxc_ip_addr} 22; do echo 'Waiting for SSH to be available...'; sleep 5; done"
    working_dir = path.module
  }
  provisioner "local-exec" {
    command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${module.dns_ha_lxc.lxc_ip_addr},' -u root --private-key ~/.ssh/id_rsa ansible/dnsdist/main.yml -e '{\"dns_ip_addrs\":${jsonencode(local.dns_ip_addrs)}}'"
    working_dir = path.module
  }
}
