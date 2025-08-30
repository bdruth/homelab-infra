module "wakapi_lxc" {
  source       = "../modules/lxc"
  lxc_hostname = "wakapi"
  lxc_ip_addr  = var.wakapi_ip_addr
  lxc_gw_addr  = var.gw_addr
  lxc_memory   = "512"
  lxc_onboot   = true
  lxc_mountpoints = [
    {
      mp      = "/opt/wakapi"
      size    = "10G"
      slot    = "0"
      key     = "0"
      storage = "local"
      backup  = true
    }
  ]
}

output "wakapi_ip" {
  value = module.wakapi_lxc.lxc_ip_addr
}
