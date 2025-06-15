module "pihole_lxc" {
  source = "../lxc"
  lxc_hostname = "pihole-${var.pihole_suffix}"
  lxc_ip_addr = var.ip_addr
  lxc_gw_addr = "192.168.7.1"
  ssh_public_keys = var.ssh_public_keys
  lxc_onboot = true
  lxc_rootfs_size = "8G"
  lxc_memory = "1024"
}

data "http" "pihole_latest_release" {
  url = "https://api.github.com/repos/pi-hole/pi-hole/releases/latest"
}

data "aws_s3_object" "pihole_teleporter_backup" {
  bucket = "homelab-configurations"
  key    = "pihole/pi-hole-pihole-teleporter.zip"
}

locals {
  pihole_latest_release = jsondecode(data.http.pihole_latest_release.response_body).name
  install_backup = var.install_backup_crontab ? "-e '{\"install_backup_crontab\": true}'" : ""
}

resource "null_resource" "run_ansible_playbook" {
  triggers = {
    pihole_version    = local.pihole_latest_release
    teleporter_backup_hash = data.aws_s3_object.pihole_teleporter_backup.etag
    container_change = module.pihole_lxc.lxc_id
    ansible_changes = sha1(join("", [for f in sort(fileset("${path.module}/../../services/pihole", "**")): filesha1("${path.module}/../../services/pihole/${f}")]))
    install_backup = local.install_backup
  }

  provisioner "local-exec" {
    command     = "until nc -zv ${module.pihole_lxc.lxc_ip_addr} 22; do echo 'Waiting for SSH to be available...'; sleep 5; done"
    working_dir = path.module
  }
  provisioner "local-exec" {
    command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${module.pihole_lxc.lxc_ip_addr},' -u root --private-key '${var.ssh_priv_key_path}' ${local.install_backup} ../../services/pihole/main.yml"
    working_dir = path.module
  }
}

resource "null_resource" "run_ansible_maintenance_tag" {
  # triggers = {
  #   always_run = "${timestamp()}"
  # }
  depends_on = [ null_resource.run_ansible_playbook ]

  provisioner "local-exec" {
    command     = "until nc -zv ${module.pihole_lxc.lxc_ip_addr} 22; do echo 'Waiting for SSH to be available...'; sleep 5; done"
    working_dir = path.module
  }
  provisioner "local-exec" {
    command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${module.pihole_lxc.lxc_ip_addr},' -u root --private-key '${var.ssh_priv_key_path}' ${local.install_backup} ../../services/pihole/main.yml --tags maintenance"
    working_dir = path.module
  }
}
