variable "gw_addr" {
  description = "network gateway address"
  type        = string
}

variable "wakapi_ip_addr" {
  description = "IP address for the wakapi LXC"
  type        = string
}

variable "ssh_priv_key_path" {
  description = "path to SSH private key"
  type        = string
}

variable "s3_backend_endpoint" {
  description = "endpoint URL to alternative s3 backend"
  type        = string
}

variable "s3_bucket_tf_state" {
  description = "bucket for IaC state"
  type        = string
}

variable "proxmox_api_url" {
  description = "API URL to manage proxmox LXC resources"
  type        = string
}
