variable "gw_addr" {
  description = "network gateway address"
  type        = string
}

variable "pihole_ip" {
  description = "IP addr for DNS HA node"
  type = string
}

variable "ssh_priv_key_path" {
  description = "path to SSH private key"
  type = string
}

variable "s3_backend_endpoint" {
  description = "endpoint URL to alternative s3 backend"
  type = string
}

variable "s3_bucket_tf_state" {
  description = "bucket for IaC state"
  type = string
}

variable "proxmox_api_url" {
  description = "API URL to manage proxmox LXC resources"
  type = string
}

variable "namespace" {
  description = "Namespace differentiator [blue|green]"
  type = string
}

variable "ssh_public_keys" {
  description = "SSH public key(s) to install in LXC"
  type        = string
}

variable "install_backup_crontab" {
  description = "Install backup crontab"
  default     = false
  type        = bool
}
