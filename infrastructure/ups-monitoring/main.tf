# LXC 105 is the live NUT server every UPS client depends on. It predates
# this stack's state (a partial 2024 import) and carries hand-added USB
# passthrough (dev0/dev1 for both APC UPSes) that the telmate provider can't
# manage, so a replacement would come back without its UPSes. This resource
# therefore describes the container exactly as it runs and the plan must stay
# at "No changes": never let an apply replace or even update it.
#
# The NUT server config itself is hand-managed (see homelab-infra-s9g); the
# old null_resource that ran services/nut/main.yml against this host was
# removed because it would have configured the server as a netclient.

moved {
  from = module.ups_monitoring_lxc.proxmox_lxc.container
  to   = proxmox_lxc.ups_monitoring
}

resource "proxmox_lxc" "ups_monitoring" {
  target_node  = "proxmox-main"
  hostname     = "ups-monitoring"
  unprivileged = true
  onboot       = true
  cores        = 2
  memory       = 512
  swap         = 512
  nameserver   = "192.168.7.3"

  features {
    nesting = true
  }

  network {
    name     = "eth0"
    bridge   = "vmbr0"
    firewall = true
    ip       = "${var.ups_monitoring_ip_addr}/24"
    gw       = var.gw_addr
    ip6      = "auto"
    hwaddr   = "BC:24:11:EB:47:FD"
  }

  rootfs {
    storage = "local"
    size    = "8G"
  }

  # Track-only: the attributes above document the live container but are not
  # enforced. The imported state lacks rootfs storage, network and features
  # (this provider version doesn't read them back), and create-only inputs
  # (ostemplate, password, ssh_public_keys) are never reported, so diffing any
  # of them forces a replacement. Change LXC 105 in Proxmox, then mirror here.
  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}

output "ups_monitoring_ip" {
  value = var.ups_monitoring_ip_addr
}
