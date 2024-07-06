terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc1"
    }
  }
  backend "s3" {
    bucket = "homelab-tf-state" # Name of the S3 bucket
    endpoints = {
      s3 = "http://synology.cusack-ruth.name:9000" # Minio endpoint
    }
    key = "homelab-infra.tfstate" # Name of the tfstate file

    region                      = "main" # Region validation will be skipped
    skip_credentials_validation = true   # Skip AWS related checks and validations
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true # Enable path-style S3 URLs (https://<HOST>/<BUCKET> https://developer.hashicorp.com/terraform/language/settings/backends/s3#use_path_style
  }
}


provider "proxmox" {
  # Configuration options
  pm_tls_insecure = false
  pm_api_url      = "https://proxmox-main.cusack-ruth.name:8006/api2/json"
}

provider "aws" {
  region                      = "main"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true
  skip_region_validation      = true
  endpoints {
    s3 = "http://synology.cusack-ruth.name:9000"
  }
}
