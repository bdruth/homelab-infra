locals {
  dns_ha_ip = "192.168.7.3"
}

module "dns_ha_lxc" {
  source = "./modules/lxc"
  lxc_hostname = local.dns_ha_ip
  lxc_ip_addr = "192.168.7.3"
  lxc_gw_addr = "192.168.7.1"
  lxc_memory = "512"
}
