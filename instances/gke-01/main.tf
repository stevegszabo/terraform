terraform {
  cloud {
    organization = "organization"
    workspaces {
      name = "project-01-xxxxxx-gke-01"
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
  gcp_instance_environment     = "eng"
  gcp_instance_project         = "project-01-xxxxxx"
  gcp_instance_dns_project     = "dns-01-xxxxxx"
  gcp_instance_name            = "gke-01"
  gcp_instance_region          = "northamerica-northeast2"
  gcp_instance_version         = "1.33.5-gke.1162000"
  gcp_instance_keyring         = "kms-01"
  gcp_instance_crypto_key      = "kms-01"
  gcp_instance_network_vpc     = "vpc-01"
  gcp_instance_network_subnet  = "vpc-01-subnet-01"
  gcp_instance_pod_cidr        = "10.0.0.0/14"
  gcp_instance_svc_cidr        = "172.16.0.0/16"
  gcp_instance_pep_cidr        = null
  gcp_instance_api_access      = []

  gcp_instance_monitoring      = true
  gcp_instance_logging         = true
  gcp_instance_http_balancing  = true
  gcp_instance_binary_auth     = true
  gcp_instance_encryption      = true
  gcp_instance_private_nodes   = true
  gcp_instance_private_api     = true
  gcp_instance_config_connect  = true

  gcp_instance_managed_projects = [
    "project-01-xxxxxx",
    "project-02-xxxxxx",
    "project-03-xxxxxx"
  ]

  gcp_instance_worker_pools = {
    system-01 = {
      machine_type        = "e2-standard-2"
      machine_disk_type   = "pd-standard"
      machine_disk_size   = 25
      machine_preemptible = false

      autoscale_min_nodes = 1
      autoscale_max_nodes = 3

      node_taints = []
      node_labels = {
        "domain.ca/environment" = local.gcp_instance_environment,
        "domain.ca/project"     = local.gcp_instance_project,
        "domain.ca/vpc"         = local.gcp_instance_network_vpc,
        "domain.ca/subnet"      = local.gcp_instance_network_subnet,
        "domain.ca/workloads"   = "system"
      }
    }
  }

  gcp_instance_accounts = {
    format("%s-gar", local.gcp_instance_name) = {
      projects          = local.gcp_instance_managed_projects
      project_roles     = ["roles/artifactregistry.reader"]
      kube_svc_accounts = ["serviceAccount:project-01-xxxxxx.svc.id.goog[base-argocd/gke-01-argocd-image-updater]"]
    },

    format("%s-arg", local.gcp_instance_name) = {
      projects          = local.gcp_instance_managed_projects
      project_roles     = ["roles/container.admin"]
      kube_svc_accounts = [
        "serviceAccount:project-01-xxxxxx.svc.id.goog[base-argocd/gke-01-argocd-server]",
        "serviceAccount:project-01-xxxxxx.svc.id.goog[base-argocd/gke-01-argocd-application-controller]"
      ]
    },

    format("%s-dns", local.gcp_instance_name) = {
      projects = [local.gcp_instance_dns_project, local.gcp_instance_project]
      project_roles     = ["roles/dns.admin"]
      kube_svc_accounts = [
        "serviceAccount:project-01-xxxxxx.svc.id.goog[base-edns/gke-01-external-dns]",
        "serviceAccount:project-01-xxxxxx.svc.id.goog[base-cm/gke-01-cert-manager]"
      ]
    }

    format("%s-gsm", local.gcp_instance_name) = {
      projects          = [local.gcp_instance_project]
      project_roles     = ["roles/secretmanager.secretAccessor"]
      kube_svc_accounts = ["serviceAccount:project-01-xxxxxx.svc.id.goog[base-eso/gke-01-external-secrets]"]
    }

    format("%s-hcv", local.gcp_instance_name) = {
      projects          = [local.gcp_instance_project]
      project_roles     = [
        "roles/cloudkms.viewer",
        "roles/cloudkms.cryptoKeyEncrypterDecrypter",
        "roles/secretmanager.admin"
      ]
      kube_svc_accounts = ["serviceAccount:project-01-xxxxxx.svc.id.goog[base-vault/gke-01-vault]"]
    }

    format("%s-cfg", local.gcp_instance_name) = {
      projects          = [local.gcp_instance_project]
      project_roles     = [
        "roles/cloudkms.viewer",
        "roles/cloudkms.cryptoKeyEncrypterDecrypter",
        "roles/storage.admin"
      ]
      kube_svc_accounts = ["serviceAccount:project-01-xxxxxx.svc.id.goog[cnrm-system/cnrm-controller-manager]"]
    }
  }
}

module "gke" {
  source                       = "app.terraform.io/organization/gke/gcp"
  version                      = "1.8.0"
  gcp_instance_environment     = local.gcp_instance_environment
  gcp_instance_project         = local.gcp_instance_project
  gcp_instance_name            = local.gcp_instance_name
  gcp_instance_region          = local.gcp_instance_region
  gcp_instance_version         = local.gcp_instance_version
  gcp_instance_keyring         = local.gcp_instance_keyring
  gcp_instance_crypto_key      = local.gcp_instance_crypto_key
  gcp_instance_network_vpc     = local.gcp_instance_network_vpc
  gcp_instance_network_subnet  = local.gcp_instance_network_subnet
  gcp_instance_pod_cidr        = local.gcp_instance_pod_cidr
  gcp_instance_svc_cidr        = local.gcp_instance_svc_cidr
  gcp_instance_pep_cidr        = local.gcp_instance_pep_cidr
  gcp_instance_http_balancing  = local.gcp_instance_http_balancing
  gcp_instance_binary_auth     = local.gcp_instance_binary_auth
  gcp_instance_encryption      = local.gcp_instance_encryption
  gcp_instance_private_nodes   = local.gcp_instance_private_nodes
  gcp_instance_private_api     = local.gcp_instance_private_api
  gcp_instance_config_connect  = local.gcp_instance_config_connect
  gcp_instance_accounts        = local.gcp_instance_accounts
  gcp_instance_worker_pools    = local.gcp_instance_worker_pools
  gcp_instance_api_access      = local.gcp_instance_api_access
  gcp_instance_logging         = local.gcp_instance_logging
  gcp_instance_monitoring      = local.gcp_instance_monitoring
}
