# Pihole DNS Configuration

## Configuration

Example `terraform.tfvars` file:

```hcl
gw_addr = "<gateway-ip-addr>"
ssh_priv_key_path = "<path-to-ssh-private-key>"
s3_backend_endpoint = "http://<your-url-to-alt-s3-api-endpoint>:9000"
s3_bucket_tf_state = "<your-bucket-name>"
proxmox_api_url = "https://<your-proxmox-api-url>:8006/api2/json"
```

The `blue.tfvars` and `green.tfvars` files are used to configure the blue and green environment details respectively. Specifically, the LXC IP addr assigned to each container is configured there.

Example:

```hcl
pihole_ip = "<lxc-container-ip>"
```
