terraform {
  cloud {
    organization = "organization"
    workspaces {
      name = "project-01-xxxxxx-jmp-01"
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
  gcp_instance_environment  = "eng"
  gcp_instance_region       = "northamerica-northeast2"
  gcp_instance_zone         = "northamerica-northeast2-a"
  gcp_instance_project      = "project-01-xxxxxx"
  gcp_instance_project_pub  = "boot-999999"
  gcp_instance_dns_pub_zone = "domain-ca"
  gcp_instance_subnet       = "vpc-01-subnet-01"
  gcp_instance_name         = "jump-eng-project-01"
  gcp_instance_machine_type = "e2-medium"
  gcp_instance_secret_key   = "jumphost-access-key"
  gcp_instance_disk_image   = "projects/ubuntu-os-cloud/global/images/ubuntu-2404-noble-amd64-v20250703"

  gcp_instance_network_tags = [
    "ingress-allow-ssh-access"
  ]

  gcp_instance_sa_roles = {
    project-01-xxxxxx = ["roles/viewer", "roles/compute.instanceAdmin.v1", "roles/iam.serviceAccountUser"]
    project-02-xxxxxx = ["roles/viewer", "roles/compute.instanceAdmin.v1", "roles/iam.serviceAccountUser"]
    project-03-xxxxxx = ["roles/viewer", "roles/compute.instanceAdmin.v1", "roles/iam.serviceAccountUser"]
  }
}

module "jmp" {
  source                    = "app.terraform.io/organization/jmp/gcp"
  version                   = "1.4.0"
  gcp_instance_environment  = local.gcp_instance_environment
  gcp_instance_machine_type = local.gcp_instance_machine_type
  gcp_instance_project      = local.gcp_instance_project
  gcp_instance_project_pub  = local.gcp_instance_project_pub
  gcp_instance_subnet       = local.gcp_instance_subnet
  gcp_instance_name         = local.gcp_instance_name
  gcp_instance_zone         = local.gcp_instance_zone
  gcp_instance_dns_pub_zone = local.gcp_instance_dns_pub_zone
  gcp_instance_disk_image   = local.gcp_instance_disk_image
  gcp_instance_sa_roles     = local.gcp_instance_sa_roles
  gcp_instance_secret_key   = local.gcp_instance_secret_key
  gcp_instance_network_tags = local.gcp_instance_network_tags
}
