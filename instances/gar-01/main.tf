terraform {
  cloud {
    organization = "organization"
    workspaces {
      name = "project-01-xxxxxx-gar-01"
    }
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.12.0"
    }
  }
}

provider "google" {
  project = local.gcp_instance_project
  region  = local.gcp_instance_region
}

locals {
  gcp_instance_project    = "project-01-xxxxxx"
  gcp_instance_region     = "northamerica-northeast2"
  gcp_instance_gar_name   = "gar-01"
  gcp_instance_keyring    = "kms-01"
  gcp_instance_crypto_key = "kms-01"
}

module "gar" {
  source                  = "app.terraform.io/organization/gar/gcp"
  version                 = "1.1.0"
  gcp_instance_project    = local.gcp_instance_project
  gcp_instance_region     = local.gcp_instance_region
  gcp_instance_name       = local.gcp_instance_gar_name
  gcp_instance_keyring    = local.gcp_instance_keyring
  gcp_instance_crypto_key = local.gcp_instance_crypto_key
}
