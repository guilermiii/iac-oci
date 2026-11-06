terraform {
  required_version = ">= 1.5.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }
  }
}

provider "oci" {
  auth                = var.auth
  config_file_profile = var.oci_config_profile
  region              = var.region
  tenancy_ocid        = var.tenancy_ocid
}
