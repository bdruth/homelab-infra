terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc8"
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
  memory   = var.lxc_memory

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${var.lxc_ip_addr}/24"
    gw     = var.lxc_gw_addr
    ip6    = "auto"
    hwaddr = var.lxc_hwaddr
  }

  rootfs {
    acl       = false
    quota     = false
    replicate = false
    ro        = false
    shared    = false
    storage   = var.lxc_storage_pool
    size      = var.lxc_rootfs_size
  }

  ostemplate      = "synology1:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
  password        = random_password.root_password.result
  ssh_public_keys = var.ssh_public_keys
  start           = true
  onboot          = var.lxc_onboot
  pool            = "terraform-prov-pool"
  target_node     = "proxmox-main"
  unprivileged    = true
}
