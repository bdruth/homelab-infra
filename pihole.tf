module "pihole-blue" {
  source        = "./modules/pihole"
  pihole_suffix = "blue"
  ip_addr       = "192.168.7.2"
}

module "pihole-green" {
  source        = "./modules/pihole"
  pihole_suffix = "green"
  ip_addr       = "192.168.7.4"
}

locals {
  dns_ip_addrs = [
    module.pihole-blue.pihole_ip,
    module.pihole-green.pihole_ip
  ]
}

output "dns_ha_ip" {
  value = module.dns_ha_lxc.lxc_ip_addr
}
