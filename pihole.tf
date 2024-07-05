module "pihole" {
  source        = "./modules/pihole"
  pihole_suffix = "blue"
  ip_addr       = "192.168.7.2"
}

output "lxc_test_ip" {
  value = module.pihole.pihole_ip
}
