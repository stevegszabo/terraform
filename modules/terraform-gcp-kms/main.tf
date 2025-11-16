locals {
  gcp_instance_name    = var.gcp_instance_name
  gcp_instance_project = var.gcp_instance_project
  gcp_instance_region  = var.gcp_instance_region
}

data "google_project" "this" {
  project_id = local.gcp_instance_project
}

resource "google_kms_key_ring" "this" {
  name     = local.gcp_instance_name
  project  = data.google_project.this.project_id
  location = local.gcp_instance_region
}

resource "google_kms_crypto_key" "encrypt" {
  name            = local.gcp_instance_name
  key_ring        = google_kms_key_ring.this.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "2419200s"
}

resource "google_kms_crypto_key" "attestor" {
  name     = format("%s-attestor", local.gcp_instance_name)
  key_ring = google_kms_key_ring.this.id
  purpose  = "ASYMMETRIC_SIGN"

  version_template {
    algorithm = "RSA_SIGN_PKCS1_4096_SHA512"
  }
}

resource "google_kms_crypto_key_iam_member" "compute" {
  crypto_key_id = google_kms_crypto_key.encrypt.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = format("serviceAccount:service-%s@compute-system.iam.gserviceaccount.com", data.google_project.this.number)
}

resource "google_kms_crypto_key_iam_member" "container" {
  crypto_key_id = google_kms_crypto_key.encrypt.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = format("serviceAccount:service-%s@container-engine-robot.iam.gserviceaccount.com", data.google_project.this.number)
}

resource "google_kms_crypto_key_iam_member" "artifactregistry" {
  crypto_key_id = google_kms_crypto_key.encrypt.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = format("serviceAccount:service-%s@gcp-sa-artifactregistry.iam.gserviceaccount.com", data.google_project.this.number)
}
