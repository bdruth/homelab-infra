gw_addr                       = "192.168.0.1"
ssh_priv_key_path             = "/path/to/id_rsa"
s3_backend_endpoint           = "https://s3.example.com"
s3_bucket_tf_state            = "example-tf-state"
proxmox_api_url               = "https://proxmox.example.com/api2/json"
pihole_blue_remote_state_key  = "path/to/pihole-blue.tfstate"
pihole_green_remote_state_key = "path/to/pihole-green.tfstate"

# The two nodes of the dnsdist HA pair, and the VRRP virtual IP that floats
# between them. Clients are pointed at dns_vip_addr, never at the node
# addresses -- the VIP is what survives a node failure.
dns_ip_addr_1 = "192.168.0.51"
dns_ip_addr_2 = "192.168.0.52"
dns_vip_addr  = "192.168.0.50"

# Installed into both nodes. Must include the key CI authenticates with, or the
# Ansible provisioner cannot reach a freshly built node.
ssh_public_keys = <<-EOT
ssh-rsa AAAA... user@example
ssh-ed25519 AAAA... ci@example
EOT
