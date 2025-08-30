variable "lxc_ip_addr" {
  description = "container ip address"
  type        = string
}

variable "lxc_gw_addr" {
  description = "container gateway address"
  type        = string
}

variable "lxc_hwaddr" {
  description = "container hardware (MAC) address"
  type        = string
  default     = null
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
  type        = string
  default     = "local"
}

variable "lxc_onboot" {
  description = "LXC containers starts on boot of proxmox, true or false"
  type        = bool
  default     = false
}

variable "lxc_rootfs_size" {
  description = "Size of the rootfs in GB for LXC containers. Default is 4GB."
  type        = string
  default     = "4G"
}

variable "lxc_mountpoints" {
  description = "Optional additional LXC mount points (mp0..mpN)."
  type = list(object({
    mp        = string,
    size      = string,
    slot      = string, # e.g. "0" for mp0
    key       = string, # usually same as slot
    storage   = string, # storage name for storage-backed, or host path for bind mount
    backup    = optional(bool),
    volume    = optional(string),
    acl       = optional(bool),
    quota     = optional(bool),
    replicate = optional(bool),
    shared    = optional(bool)
  }))
  default = []
}
