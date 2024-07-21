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

variable "ssh_public_keys" {
  description = "SSH public key(s) to install in LXC"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDDksBMkSWfRLuTAS30E/ZtzY74laZMxa7F6RGyDEJfObQaAyuf1FAmIdTEVgwDJ8gDqtUTy7tDv6reSqGyXNKmEgoNOBdJ4RXPAobZSXX6X2PsgNXd/mrZqHcc/RN4wkJpHmgLoj2ZJuE30Ld0/csP98GeusGREznCEhzuQ3a8N/YVkUtz1lgYKW7yWf5XKD1s/IQBwGmI4eA4I7EkljXtEFIqlEXF4zXNPRpSh+iND++zKdSFZ+ve7ZxWlTlwUCyn5wMRLYNWc+jk84ViX/mQr++dPihC/PVg58UwYK74w1pMfqrrZaHGPuKC64x3x3P1ytblEd752r82iAHTNL8R"
}

variable "lxc_storage_pool" {
  description = "LXC storage pool to use for containers"
  type         = string
  default      = "fe3b3982-b346-4780-9c84-75bc50c4d81f"
}
