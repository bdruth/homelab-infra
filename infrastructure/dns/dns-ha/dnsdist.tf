module "dns_ha_lxc" {
  source       = "../../modules/lxc"
  lxc_hostname = "dns-ha"
  lxc_ip_addr  = var.dns_ip_addr
  lxc_gw_addr  = var.gw_addr
  lxc_memory   = "512"
  lxc_onboot   = true
  lxc_hwaddr   = "BC:24:11:27:F6:81"
  # 127.0.0.1 = local dnsdist; 192.168.7.2 (pihole-blue) is one of dnsdist's
  # upstreams and covers the brief boot window before dnsdist binds :53. PVE
  # otherwise inherits 100.100.100.100 (Tailscale MagicDNS) here, which is
  # unreachable from this LXC (userspace-networking, no tailscale0).
  lxc_nameserver = "127.0.0.1 192.168.7.2"
}

## The HA pair: dns-ha-1 (.12) and dns-ha-2 (.13).
##
## These are built alongside the original single node (dns-ha, .3) rather than
## by renumbering it. Nothing about the live container is mutated, and the pair
## can be proven healthy before anything is retired. Phase 2 stops dns-ha and
## hands .3 to keepalived as a unicast VRRP VIP floating across this pair, so
## .3 remains the LAN's DNS address permanently and eero never has to change.
##
## Deliberately separate module blocks rather than converting dns_ha_lxc to
## for_each: that would change the existing module's address to
## module.dns_ha_lxc["dns-ha"] and destroy/recreate the container currently
## serving all LAN DNS. The duplication is the cheaper trade.
##
## Each node points its boot-window resolver at a different Pi-hole so the pair
## has no common dependency before dnsdist binds :53.
module "dns_ha_lxc_1" {
  source         = "../../modules/lxc"
  lxc_hostname   = "dns-ha-1"
  lxc_ip_addr    = var.dns_ip_addr_1
  lxc_gw_addr    = var.gw_addr
  lxc_memory     = "512"
  lxc_swap       = "0"
  lxc_onboot     = true
  lxc_hwaddr     = "BC:24:11:27:F6:83"
  lxc_nameserver = "127.0.0.1 192.168.7.2"
  ## The module default installs only the RSA key. CI authenticates with the
  ## ed25519 key, which the original dns-ha container has from an out-of-band
  ## step -- so a freshly built node is unreachable from CI without this.
  ## Every other stack (pihole, wakapi, matterbridge) already passes it.
  ## Deliberately NOT set on module.dns_ha_lxc: ssh_public_keys is ForceNew,
  ## so adding it there would destroy and recreate the live DNS container.
  ssh_public_keys = var.ssh_public_keys
}

module "dns_ha_lxc_2" {
  source          = "../../modules/lxc"
  lxc_hostname    = "dns-ha-2"
  lxc_ip_addr     = var.dns_ip_addr_2
  lxc_gw_addr     = var.gw_addr
  lxc_memory      = "512"
  lxc_swap        = "0"
  lxc_onboot      = true
  lxc_hwaddr      = "BC:24:11:27:F6:82"
  lxc_nameserver  = "127.0.0.1 192.168.7.4"
  ssh_public_keys = var.ssh_public_keys
}

locals {
  dns_ip_addrs = [
    data.terraform_remote_state.pihole_blue.outputs.pihole_ip,
    data.terraform_remote_state.pihole_green.outputs.pihole_ip
  ]
}

resource "null_resource" "install_dnsdist" {
  ## The live node converges last: if a dnsdist change breaks the new nodes,
  ## the apply aborts before reaching the resolver the LAN is currently using.
  depends_on = [null_resource.install_dnsdist_2]

  triggers = {
    ansible_changes  = sha1(join("", [for f in sort(fileset("${path.module}/../../../services/dnsdist", "**")) : filesha1("${path.module}/../../../services/dnsdist/${f}")]))
    container_change = module.dns_ha_lxc.lxc_id
    dns_ip_addrs     = jsonencode(local.dns_ip_addrs)
  }

  provisioner "local-exec" {
    command     = "until nc -zv ${module.dns_ha_lxc.lxc_ip_addr} 22; do echo 'Waiting for SSH to be available...'; sleep 5; done"
    working_dir = path.module
  }
  provisioner "local-exec" {
    command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${module.dns_ha_lxc.lxc_ip_addr},' -u root --private-key ${var.ssh_priv_key_path} ../../../services/dnsdist/main.yml -e '{\"dns_ip_addrs\":${jsonencode(local.dns_ip_addrs)}}' -e 'ansible_python_interpreter=/usr/bin/python3'"
    working_dir = path.module
  }
}

resource "null_resource" "install_dnsdist_1" {
  triggers = {
    ansible_changes  = sha1(join("", [for f in sort(fileset("${path.module}/../../../services/dnsdist", "**")) : filesha1("${path.module}/../../../services/dnsdist/${f}")]))
    container_change = module.dns_ha_lxc_1.lxc_id
    dns_ip_addrs     = jsonencode(local.dns_ip_addrs)
  }

  provisioner "local-exec" {
    command     = "until nc -zv ${module.dns_ha_lxc_1.lxc_ip_addr} 22; do echo 'Waiting for SSH to be available...'; sleep 5; done"
    working_dir = path.module
  }
  provisioner "local-exec" {
    command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${module.dns_ha_lxc_1.lxc_ip_addr},' -u root --private-key ${var.ssh_priv_key_path} ../../../services/dnsdist/main.yml -e '{\"dns_ip_addrs\":${jsonencode(local.dns_ip_addrs)}}' -e 'ansible_python_interpreter=/usr/bin/python3'"
    working_dir = path.module
  }
}

resource "null_resource" "install_dnsdist_2" {
  ## Serialized behind node 1. Terraform runs provisioners in parallel by
  ## default, and concurrent ansible-playbook invocations race on the shared
  ## pkgx venv (observed: "No such file or directory:
  ## /root/.pkgx/ansible.com/v2.21.2/venv/bin/python").
  ##
  ## Serialization is also the safer rollout: a dnsdist config change applied
  ## to every resolver at once would take them all down together. Chained, the
  ## new nodes converge first and a failure aborts the apply before the live
  ## node at .3 is touched.
  depends_on = [null_resource.install_dnsdist_1]

  triggers = {
    ansible_changes  = sha1(join("", [for f in sort(fileset("${path.module}/../../../services/dnsdist", "**")) : filesha1("${path.module}/../../../services/dnsdist/${f}")]))
    container_change = module.dns_ha_lxc_2.lxc_id
    dns_ip_addrs     = jsonencode(local.dns_ip_addrs)
  }

  provisioner "local-exec" {
    command     = "until nc -zv ${module.dns_ha_lxc_2.lxc_ip_addr} 22; do echo 'Waiting for SSH to be available...'; sleep 5; done"
    working_dir = path.module
  }
  provisioner "local-exec" {
    command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${module.dns_ha_lxc_2.lxc_ip_addr},' -u root --private-key ${var.ssh_priv_key_path} ../../../services/dnsdist/main.yml -e '{\"dns_ip_addrs\":${jsonencode(local.dns_ip_addrs)}}' -e 'ansible_python_interpreter=/usr/bin/python3'"
    working_dir = path.module
  }
}

output "dns_ha_ip" {
  value = module.dns_ha_lxc.lxc_ip_addr
}

output "dns_ha_1_ip" {
  value = module.dns_ha_lxc_1.lxc_ip_addr
}

output "dns_ha_2_ip" {
  value = module.dns_ha_lxc_2.lxc_ip_addr
}
