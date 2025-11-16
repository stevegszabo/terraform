terraform {
  cloud {
    organization = "organization"
    workspaces {
      name = "project-01-xxxxxx-kms-01"
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
  gcp_instance_name    = "kms-01"
  gcp_instance_project = "project-01-xxxxxx"
  gcp_instance_region  = "northamerica-northeast2"
}

module "kms" {
  source               = "app.terraform.io/organization/kms/gcp"
  version              = "1.2.1"
  gcp_instance_name    = local.gcp_instance_name
  gcp_instance_project = local.gcp_instance_project
  gcp_instance_region  = local.gcp_instance_region
}
