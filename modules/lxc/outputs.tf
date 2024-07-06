output "lxc_ip_addr" {
  value = split("/", proxmox_lxc.container.network[0].ip)[0]
}

output "lxc_id" {
  value = proxmox_lxc.container.id
}
