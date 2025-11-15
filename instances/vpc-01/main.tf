terraform {
  cloud {
    organization = "organization"
    workspaces {
      name = "project-01-xxxxxx-vpc-01"
    }
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.12.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.12.0"
    }
  }
}

provider "google" {
  project = local.gcp_instance_project
  region  = local.gcp_instance_region
}

provider "google-beta" {
  project = local.gcp_instance_project
  region  = local.gcp_instance_region
}

locals {
  gcp_instance_name            = "vpc-01"
  gcp_instance_project         = "project-01-xxxxxx"
  gcp_instance_create_dns_zone = true
  gcp_instance_zone            = "eng"
  gcp_instance_domain          = "domain.ca"
  gcp_instance_region          = "northamerica-northeast2"
  gcp_instance_exclude_cidrs   = ["10.0.0.0/14", "172.16.0.0/16"]
  gcp_instance_psc_address     = "192.168.1.10"
  gcp_instance_psc_forward     = "eng"

  gcp_instance_firewall_rules = {
    ingress-allow-ssh-access = {
      direction          = "INGRESS"
      source_ranges      = ["127.0.0.1/32"]
      destination_ranges = null
      target_tags        = ["ingress-allow-ssh-access"]
      priority           = 1000
      protocol           = "tcp"
      ports              = ["22"]
    }
  }

  gcp_instance_subnets = {
    format("%s-subnet-00", local.gcp_instance_name) = {
      cidr    = "192.168.10.0/24"
      purpose = "PRIVATE"
    }
    format("%s-subnet-01", local.gcp_instance_name) = {
      cidr    = "192.168.20.0/24"
      purpose = "PRIVATE"
    }
  }
}

module "vpc" {
  source                       = "app.terraform.io/organization/vpc/gcp"
  version                      = "1.8.0"
  gcp_instance_name            = local.gcp_instance_name
  gcp_instance_project         = local.gcp_instance_project
  gcp_instance_create_dns_zone = local.gcp_instance_create_dns_zone
  gcp_instance_zone            = local.gcp_instance_zone
  gcp_instance_domain          = local.gcp_instance_domain
  gcp_instance_exclude_cidrs   = local.gcp_instance_exclude_cidrs
  gcp_instance_firewall_rules  = local.gcp_instance_firewall_rules
  gcp_instance_subnets         = local.gcp_instance_subnets
  gcp_instance_psc_address     = local.gcp_instance_psc_address
  gcp_instance_psc_forward     = local.gcp_instance_psc_forward
}
