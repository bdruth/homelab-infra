terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc8"
    }
  }
  backend "s3" {
    region                      = "main" # Region validation will be skipped
    skip_credentials_validation = true   # Skip AWS related checks and validations
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true # Enable path-style S3 URLs
  }
}

provider "proxmox" {
  pm_tls_insecure = false
  pm_api_url      = var.proxmox_api_url
}

provider "aws" {
  region                      = "main"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true
  skip_region_validation      = true
  endpoints {
    s3 = var.s3_backend_endpoint
  }
}

locals {
  remote_state_config_defaults = {
    region                      = "main"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true
    skip_region_validation      = true
    endpoints = {
      s3 = var.s3_backend_endpoint
    }
  }
}
