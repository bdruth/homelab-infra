module "pihole_lxc" {
  source = "../lxc"
  lxc_hostname = "pihole-${var.pihole_suffix}"
  lxc_ip_addr = var.ip_addr
  lxc_gw_addr = "192.168.7.1"
}

data "http" "pihole_latest_release" {
  url = "https://api.github.com/repos/pi-hole/pi-hole/releases/latest"
}

data "aws_s3_object" "pihole_teleporter_backup" {
  bucket = "homelab-configurations"
  key    = "pihole/pi-hole-pihole-teleporter.tar.gz"
}

locals {
  pihole_latest_release = jsondecode(data.http.pihole_latest_release.response_body).name
}

resource "null_resource" "run_ansible_playbook" {
  triggers = {
    pihole_version    = local.pihole_latest_release
    setupVars_hash    = filesha256("${path.module}/../../ansible/pihole/setupVars.conf.j2")
    ansible_conf_hash = filesha256("${path.module}/../../ansible/pihole/main.yml")
    teleporter_backup_hash = data.aws_s3_object.pihole_teleporter_backup.etag
    container_change = module.pihole_lxc.lxc_id
  }

  provisioner "local-exec" {
    command     = "until nc -zv ${module.pihole_lxc.lxc_ip_addr} 22; do echo 'Waiting for SSH to be available...'; sleep 5; done"
    working_dir = path.module
  }
  provisioner "local-exec" {
    command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${module.pihole_lxc.lxc_ip_addr},' -u root --private-key ~/.ssh/id_rsa ../../ansible/pihole/main.yml"
    working_dir = path.module
  }
}
