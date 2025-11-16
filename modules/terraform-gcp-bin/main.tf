locals {
  gcp_instance_region                   = var.gcp_instance_region
  gcp_instance_project                  = var.gcp_instance_project
  gcp_instance_clusters                 = var.gcp_instance_clusters
  gcp_instance_common_images            = distinct(var.gcp_instance_common_images)

  gcp_instance_default_evaluation_mode  = "ALWAYS_DENY"
  gcp_instance_default_enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
  gcp_instance_cluster_evaluation_mode  = "REQUIRE_ATTESTATION"
  gcp_instance_cluster_enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"

  gcp_instance_addmission_rules = flatten([
    for index, value in local.gcp_instance_clusters : index
  ])

  gcp_instance_addmission_whitelist = flatten([
    for index, value in local.gcp_instance_clusters : distinct(value["images"])
  ])
}

data "google_project" "this" {
  project_id = local.gcp_instance_project
}

data "google_kms_key_ring" "this" {
  for_each = local.gcp_instance_clusters
  project  = data.google_project.this.project_id
  location = local.gcp_instance_region
  name     = each.value["keyring"]
}

data "google_kms_crypto_key" "this" {
  for_each = local.gcp_instance_clusters
  name     = each.value["cryptokey"]
  key_ring = data.google_kms_key_ring.this[each.key].id
}

data "google_kms_crypto_key_version" "this" {
  for_each   = local.gcp_instance_clusters
  crypto_key = data.google_kms_crypto_key.this[each.key].id
}

resource "google_binary_authorization_attestor" "this" {
  for_each = local.gcp_instance_clusters
  name     = each.key

  attestation_authority_note {
    note_reference = google_container_analysis_note.this[each.key].name

    public_keys {
      id = data.google_kms_crypto_key_version.this[each.key].id

      pkix_public_key {
        public_key_pem      = data.google_kms_crypto_key_version.this[each.key].public_key[0].pem
        signature_algorithm = data.google_kms_crypto_key_version.this[each.key].public_key[0].algorithm
      }
    }
  }
}

resource "google_container_analysis_note" "this" {
  for_each = local.gcp_instance_clusters
  name     = each.key

  attestation_authority {
    hint {
      human_readable_name = each.key
    }
  }
}

resource "google_binary_authorization_policy" "this" {
  default_admission_rule {
    evaluation_mode  = local.gcp_instance_default_evaluation_mode
    enforcement_mode = local.gcp_instance_default_enforcement_mode
  }

  dynamic "admission_whitelist_patterns" {
    for_each = concat(local.gcp_instance_common_images, local.gcp_instance_addmission_whitelist)

    content {
      name_pattern = admission_whitelist_patterns.value
    }
  }

  dynamic "cluster_admission_rules" {
    for_each = local.gcp_instance_addmission_rules

    content {
      cluster                 = format("%s.%s", local.gcp_instance_region, cluster_admission_rules.value)
      evaluation_mode         = local.gcp_instance_cluster_evaluation_mode
      enforcement_mode        = local.gcp_instance_cluster_enforcement_mode
      require_attestations_by = [google_binary_authorization_attestor.this[cluster_admission_rules.value].name]
    }
  }
}
