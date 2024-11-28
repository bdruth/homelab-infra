gw_addr = "192.168.0.1"
ssh_priv_key_path = "~/.ssh/id_dsa"
s3_backend_endpoint = "https://minio.example.com"
s3_bucket_tf_state = "homelab-tf-state-example"
proxmox_api_url = "https://proxmox.example.com/api2/json"
ssh_public_keys = <<-EOT
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJC+X4072kVGyFatAC8g/9r9T3ZNXy11blM5pm8v2PDQ ssh-user1
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDK8S9n0izq3hXL8dbultzZFGjyZ+b8zaczT6ZltVYbb ssh-user2
EOT
