module "matterbridge_lxc" {
  source          = "../modules/lxc"
  lxc_hostname    = "matterbridge"
  lxc_ip_addr     = var.matterbridge_ip_addr
  lxc_gw_addr     = var.gw_addr
  lxc_memory      = "1024"
  lxc_onboot      = true
  ssh_public_keys = var.ssh_public_keys
  lxc_mountpoints = [
    {
      mp      = "/opt/matterbridge"
      size    = "10G"
      slot    = "0"
      key     = "0"
      storage = "local"
      backup  = true
    }
  ]
  lxc_nameserver = "192.168.7.3"
}

resource "null_resource" "run_ansible_playbook" {
  triggers = {
    container_change = module.matterbridge_lxc.lxc_id
    ansible_changes  = sha1(join("", [for f in sort(fileset("${path.module}/../../services/matterbridge", "**")) : filesha1("${path.module}/../../services/matterbridge/${f}")]))
  }

  provisioner "local-exec" {
    command     = "until nc -zv ${module.matterbridge_lxc.lxc_ip_addr} 22; do echo 'Waiting for SSH to be available...'; sleep 5; done"
    working_dir = path.module
  }
  provisioner "local-exec" {
    command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${module.matterbridge_lxc.lxc_ip_addr},' -u root --private-key '${var.ssh_priv_key_path}' -e 'ansible_python_interpreter=/usr/bin/python3' ../../services/matterbridge/main.yml"
    working_dir = path.module
  }
}

output "matterbridge_ip" {
  value = module.matterbridge_lxc.lxc_ip_addr
}
