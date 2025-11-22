terraform {
  cloud {
    organization = "organization"
    workspaces {
      name = "project-01-xxxxxx-cas-01"
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
}

provider "google-beta" {
  project = local.gcp_instance_project
}

locals {
  gcp_instance_project    = "project-01-xxxxxx"
  gcp_instance_region     = "northamerica-northeast2"
  gcp_instance_name       = "cas-alpha"
  gcp_instance_tier       = "ENTERPRISE"
  gcp_instance_encoding   = "PEM"
  gcp_instance_bucket     = "gcs-01-xxxxxx"
  gcp_instance_keyring    = "kms-01"
  gcp_instance_crypto_key = "kms-01-attestor"
  gcp_instance_enabled    = false

  gcp_instance_sub_depth  = 1
  gcp_instance_sub_life   = "31536000s"
  gcp_instance_sub_org    = "domain.ca"
  gcp_instance_sub_com    = "subordinate"
  gcp_instance_sub_san    = ["istiod.istio-system.svc"]
  gcp_instance_sub_crt    = file("subordinate.crt")
  gcp_instance_sub_root   = file("rootCA.crt")

  gcp_instance_crypto_key_elements = split("/", data.google_kms_crypto_key_latest_version.this.version)
  gcp_instance_crypto_key_element  = local.gcp_instance_crypto_key_elements[length(local.gcp_instance_crypto_key_elements) - 1]
  gcp_instance_crypto_key_version  = format("%s/cryptoKeyVersions/%s", data.google_kms_crypto_key.this.id, local.gcp_instance_crypto_key_element)

  gcp_instance_identity = "group:project-01-xxxxxx.svc.id.goog:/allAuthenticatedUsers/"
}

data "google_storage_bucket" "this" {
  name = local.gcp_instance_bucket
}

data "google_kms_key_ring" "this" {
  name     = local.gcp_instance_keyring
  location = local.gcp_instance_region
}

data "google_kms_crypto_key" "this" {
  name     = local.gcp_instance_crypto_key
  key_ring = data.google_kms_key_ring.this.id
}

data "google_kms_crypto_key_latest_version" "this" {
  crypto_key = data.google_kms_crypto_key.this.id
}

data "google_privateca_certificate_authority" "this" {
  location                 = local.gcp_instance_region
  pool                     = google_privateca_ca_pool.this.name
  certificate_authority_id = google_privateca_certificate_authority.this.certificate_authority_id
}

resource "google_project_service_identity" "this" {
  provider = google-beta
  service  = "privateca.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "signer" {
  crypto_key_id = data.google_kms_crypto_key.this.id
  role          = "roles/cloudkms.signerVerifier"
  member        = google_project_service_identity.this.member
}

resource "google_kms_crypto_key_iam_member" "viewer" {
  crypto_key_id = data.google_kms_crypto_key.this.id
  role          = "roles/viewer"
  member        = google_project_service_identity.this.member
}

resource "google_storage_bucket_iam_member" "this" {
  bucket  = data.google_storage_bucket.this.name
  role    = "roles/storage.admin"
  member  = google_project_service_identity.this.member
}

resource "google_privateca_ca_pool_iam_member" "workload" {
  ca_pool = google_privateca_ca_pool.this.id
  role    = "roles/privateca.workloadCertificateRequester"
  member  = local.gcp_instance_identity
}

resource "google_privateca_ca_pool_iam_member" "auditor" {
  ca_pool = google_privateca_ca_pool.this.id
  role    = "roles/privateca.auditor"
  member  = local.gcp_instance_identity
}

resource "google_privateca_ca_pool" "this" {
  name     = local.gcp_instance_name
  location = local.gcp_instance_region
  tier     = local.gcp_instance_tier

  publishing_options {
    publish_ca_cert = true
    publish_crl     = false
    encoding_format = local.gcp_instance_encoding
  }
}

resource "google_privateca_certificate_authority" "this" {
  pool                                   = google_privateca_ca_pool.this.name
  location                               = local.gcp_instance_region
  certificate_authority_id               = local.gcp_instance_sub_com
  lifetime                               = local.gcp_instance_sub_life
  desired_state                          = local.gcp_instance_enabled ? "ENABLED" : "STAGED"
  pem_ca_certificate                     = local.gcp_instance_enabled ? local.gcp_instance_sub_crt : null
  gcs_bucket                             = data.google_storage_bucket.this.name
  type                                   = "SUBORDINATE"
  deletion_protection                    = false
  ignore_active_certificates_on_deletion = true
  skip_grace_period                      = true

  depends_on = [
    google_kms_crypto_key_iam_member.signer,
    google_kms_crypto_key_iam_member.viewer
  ]

  dynamic "subordinate_config" {
    for_each = local.gcp_instance_enabled ? [0] : []

    content {
      pem_issuer_chain {
        pem_certificates = [local.gcp_instance_sub_root]
      }
    }
  }

  key_spec {
    cloud_kms_key_version = local.gcp_instance_crypto_key_version
  }

  config {
    subject_config {
      subject {
        organization = local.gcp_instance_sub_org
        common_name  = local.gcp_instance_sub_com
      }
      subject_alt_name {
        dns_names = local.gcp_instance_sub_san
      }
    }
    x509_config {
      ca_options {
        is_ca = true
        max_issuer_path_length = local.gcp_instance_sub_depth
      }
      key_usage {
        base_key_usage {
          cert_sign = true
          crl_sign  = true
        }
        extended_key_usage {
        }
      }
    }
  }
}
