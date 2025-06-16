# DNS High Availability Configuration

## Configuration

Example `terraform.tfvars` file:

```hcl
gw_addr = "<gateway-ip-addr>"
dns_ip_addr = "<lxc-container-ip>"
ssh_priv_key_path = "<path-to-ssh-private-key>"
s3_backend_endpoint = "http://<your-url-to-alt-s3-api-endpoint>:9000"
s3_bucket_tf_state = "<your-bucket-name>"
proxmox_api_url = "https://<your-proxmox-api-url>:8006/api2/json"
pihole_blue_remote_state_key = "<unique-name-of-your-blue-pihole-state-file>.tfstate"
pihole_green_remote_state_key = "<unique-name-of-your-green-pihole-state-file>.tfstate"
```
