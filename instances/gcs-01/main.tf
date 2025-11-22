terraform {
  cloud {
    organization = "organization"
    workspaces {
      name = "project-01-xxxxxx-gcs-01"
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
}

locals {
  gcp_instance_project    = "project-01-xxxxxx"
  gcp_instance_region     = "northamerica-northeast2"
  gcp_instance_name       = "gcs-01"
  gcp_instance_keyring    = "kms-01"
  gcp_instance_crypto_key = "kms-01"
}

data "google_storage_project_service_account" "this" {
}

data "google_kms_key_ring" "this" {
  name     = local.gcp_instance_keyring
  location = local.gcp_instance_region
}

data "google_kms_crypto_key" "this" {
  name     = local.gcp_instance_crypto_key
  key_ring = data.google_kms_key_ring.this.id
}

resource "random_string" "this" {
  length  = 6
  special = false
}

resource "google_kms_crypto_key_iam_member" "this" {
  crypto_key_id = data.google_kms_crypto_key.this.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = format("serviceAccount:%s", data.google_storage_project_service_account.this.email_address)
}

resource "google_storage_bucket" "this" {
  name                        = format("%s-%s", local.gcp_instance_name, lower(random_string.this.result))
  location                    = local.gcp_instance_region
  force_destroy               = true
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  storage_class               = "STANDARD"
  depends_on                  = [google_kms_crypto_key_iam_member.this]

  hierarchical_namespace {
    enabled = true
  }

  encryption {
    default_kms_key_name = data.google_kms_crypto_key.this.id
  }
}
