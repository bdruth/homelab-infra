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

resource "proxmox_lxc" "container" {
  features {
    nesting = true
  }
  hostname = var.lxc_hostname
  memory = var.lxc_memory

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${var.lxc_ip_addr}/24"
    gw     = var.lxc_gw_addr
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
