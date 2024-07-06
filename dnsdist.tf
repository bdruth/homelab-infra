module "dns_ha_lxc" {
  source = "./modules/lxc"
  lxc_hostname = "dns-ha"
  lxc_ip_addr = "192.168.7.3"
  lxc_gw_addr = "192.168.7.1"
  lxc_memory = "512"
}
