module "pihole" {
  source        = "../../modules/pihole"
  pihole_suffix = var.namespace
  ip_addr       = var.pihole_ip
  ssh_public_keys = var.ssh_public_keys
}

output "pihole_ip" {
  value = module.pihole.pihole_ip
}
