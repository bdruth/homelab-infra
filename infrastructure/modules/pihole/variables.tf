variable "pihole_suffix" {
  description = "pihole hostname (prefixed with 'pihole') [REQUIRED]"
  type        = string
}

variable "ip_addr" {
  description = "pihole ip address"
  type        = string
}

variable "gw_addr" {
  description = "pihole gateway address"
  type        = string
}

variable "ssh_public_keys" {
  description = "SSH public key(s) to install in LXC"
  type        = string
}

variable "ssh_priv_key_path" {
  description = "path to SSH private key"
  type        = string
}

variable "install_backup_crontab" {
  description = "Install backup crontab"
  default     = false
  type        = bool
}
