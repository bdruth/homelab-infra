variable "lxc_ip_addr" {
  description = "container ip address"
  type        = string
}

variable "lxc_gw_addr" {
  description = "container gateway address"
  type        = string
}

variable "lxc_hostname" {
  description = "container hostname"
  type        = string
}

variable "lxc_memory" {
  description = "container hostname"
  type        = string
  default     = null
}
