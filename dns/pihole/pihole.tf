moved {
  from = module.pihole-green
  to   = module.pihole
}


module "pihole" {
  source        = "../../modules/pihole"
  pihole_suffix = var.namespace
  ip_addr       = var.pihole_ip
}

output "pihole_ip" {
  value = module.pihole.pihole_ip
}
