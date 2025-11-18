terraform {
  cloud {
    organization = "organization"
    workspaces {
      name = "project-01-xxxxxx-hub-01"
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
  gcp_instance_region  = "northamerica-northeast2"
  gcp_instance_name    = "hub-01"
  gcp_instance_project = "project-01-xxxxxx"

  gcp_instance_members = {
    gke-01 = {
      location         = local.gcp_instance_region
      policycontroller = true
      servicemesh      = false
    }
  }
}

module "hub" {
  source               = "app.terraform.io/organization/hub/gcp"
  version              = "1.1.2"
  gcp_instance_name    = local.gcp_instance_name
  gcp_instance_project = local.gcp_instance_project
  gcp_instance_members = local.gcp_instance_members
}
