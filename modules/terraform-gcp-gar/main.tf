locals {
  gcp_instance_project    = var.gcp_instance_project
  gcp_instance_region     = var.gcp_instance_region
  gcp_instance_name       = var.gcp_instance_name
  gcp_instance_keyring    = var.gcp_instance_keyring
  gcp_instance_crypto_key = var.gcp_instance_crypto_key
}

data "google_project" "this" {
  project_id = local.gcp_instance_project
}

data "google_kms_key_ring" "this" {
  name     = local.gcp_instance_keyring
  location = local.gcp_instance_region
}

data "google_kms_crypto_key" "this" {
  name     = local.gcp_instance_crypto_key
  key_ring = data.google_kms_key_ring.this.id
}

resource "google_artifact_registry_repository" "this" {
  repository_id = local.gcp_instance_name
  kms_key_name  = data.google_kms_crypto_key.this.id
  mode          = "STANDARD_REPOSITORY"
  format        = "DOCKER"

  docker_config {
    immutable_tags = true
  }
}
