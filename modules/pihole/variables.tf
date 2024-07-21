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
  default     = "192.168.7.1"
}

variable "ssh_public_keys" {
  description = "SSH public key(s) to install in LXC"
  type        = string
}
