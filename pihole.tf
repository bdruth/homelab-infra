module "pihole" {
  source        = "./modules/pihole"
  pihole_suffix = "blue"
  ip_addr       = "192.168.7.2"
}

output "dns_ha_ip" {
  value = module.dns_ha_lxc.lxc_ip_addr
}
