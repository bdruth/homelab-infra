terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc1"
    }
  }
}

provider "proxmox" {
  # Configuration options
    pm_tls_insecure = false
    pm_api_url = "https://proxmox-main.cusack-ruth.name:8006/api2/json"
}
