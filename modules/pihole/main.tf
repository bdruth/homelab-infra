terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc1"
    }
  }
}

resource "random_password" "root_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "proxmox_lxc" "pihole" {
  features {
    nesting = true
  }
  hostname = "pihole-${var.pihole_suffix}"

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${var.ip_addr}/24"
    gw     = var.gw_addr
    ip6    = "auto"
  }

  rootfs {
    acl       = false
    quota     = false
    replicate = false
    ro        = false
    shared    = false
    storage   = "local"
    size      = "4G"
  }

  ostemplate      = "f39ac8b4-7319-42ec-b12e-dd3d4d98a85f:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"
  password        = random_password.root_password.result
  ssh_public_keys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDDksBMkSWfRLuTAS30E/ZtzY74laZMxa7F6RGyDEJfObQaAyuf1FAmIdTEVgwDJ8gDqtUTy7tDv6reSqGyXNKmEgoNOBdJ4RXPAobZSXX6X2PsgNXd/mrZqHcc/RN4wkJpHmgLoj2ZJuE30Ld0/csP98GeusGREznCEhzuQ3a8N/YVkUtz1lgYKW7yWf5XKD1s/IQBwGmI4eA4I7EkljXtEFIqlEXF4zXNPRpSh+iND++zKdSFZ+ve7ZxWlTlwUCyn5wMRLYNWc+jk84ViX/mQr++dPihC/PVg58UwYK74w1pMfqrrZaHGPuKC64x3x3P1ytblEd752r82iAHTNL8R"
  start           = true
  pool            = "terraform-prov-pool"
  target_node     = "proxmox-main"
  unprivileged    = true
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
    setupVars_hash    = filesha256("${path.module}/../../ansible/pihole/setupVars.conf")
    ansible_conf_hash = filesha256("${path.module}/../../ansible/pihole/main.yml")
    teleporter_backup_hash = data.aws_s3_object.pihole_teleporter_backup.etag
    container_change = proxmox_lxc.pihole.id
  }

  provisioner "local-exec" {
    command     = "until nc -zv ${split("/", proxmox_lxc.pihole.network[0].ip)[0]} 22; do echo 'Waiting for SSH to be available...'; sleep 5; done"
    working_dir = path.module
  }
  provisioner "local-exec" {
    command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${split("/", proxmox_lxc.pihole.network[0].ip)[0]},' -u root --private-key ~/.ssh/id_rsa ../../ansible/pihole/main.yml"
    working_dir = path.module
  }
}

output "pihole_ip" {
  value = split("/", proxmox_lxc.pihole.network[0].ip)[0]
}
