module "ups_monitoring_lxc" {
source = "../modules/lxc"
  lxc_hostname = "ups"
  lxc_ip_addr = var.ups_monitoring_ip_addr
  lxc_gw_addr = var.gw_addr
  lxc_memory = "512"
  lxc_onboot = true
}

resource "null_resource" "install_nut_ansible" {
  triggers = {
    ansible_conf_hash = filesha256("${path.module}/../../../services/nut/main.yml")
    container_change = module.ups_monitoring_lxc.lxc_id
  }

  provisioner "local-exec" {
    command     = "until nc -zv ${module.ups_monitoring_lxc.lxc_ip_addr} 22; do echo 'Waiting for SSH to be available...'; sleep 5; done"
    working_dir = path.module
  }
  provisioner "local-exec" {
    command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${module.ups_monitoring_lxc.lxc_ip_addr},' -u root --private-key ${var.ssh_priv_key_path} ../../../services/nut/main.yml"
    working_dir = path.module
  }
}

output "ups_monitoring_ip" {
  value = module.ups_monitoring_lxc.lxc_ip_addr
}
