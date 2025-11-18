locals {
  gcp_instance_name    = var.gcp_instance_name
  gcp_instance_project = var.gcp_instance_project
  gcp_instance_members = var.gcp_instance_members

  gcp_instance_policy_members = {
    for index, value in local.gcp_instance_members : index => value if value["policycontroller"]
  }

  gcp_instance_mesh_members = {
    for index, value in local.gcp_instance_members : index => value if value["servicemesh"]
  }
}

data "google_container_cluster" "this" {
  for_each = local.gcp_instance_members
  name     = each.key
  location = each.value["location"]
}

resource "google_gke_hub_membership" "this" {
  for_each      = local.gcp_instance_members
  membership_id = each.key

  endpoint {
    gke_cluster {
      resource_link = format("//container.googleapis.com/%s", data.google_container_cluster.this[each.key].id)
    }
  }
}

resource "google_gke_hub_feature" "mesh" {
  name     = "servicemesh"
  location = "global"
}

resource "google_gke_hub_feature" "policy" {
  name     = "policycontroller"
  location = "global"
}

resource "google_gke_hub_feature_membership" "mesh" {
  for_each   = local.gcp_instance_mesh_members
  feature    = google_gke_hub_feature.mesh.name
  membership = google_gke_hub_membership.this[each.key].membership_id
  location   = "global"

  mesh {
    management = "MANAGEMENT_AUTOMATIC"
  }
}

resource "google_gke_hub_feature_membership" "policy" {
  for_each   = local.gcp_instance_policy_members
  feature    = google_gke_hub_feature.policy.name
  membership = google_gke_hub_membership.this[each.key].membership_id
  location   = "global"

  policycontroller {
    policy_controller_hub_config {
      install_spec              = "INSTALL_SPEC_ENABLED"
      referential_rules_enabled = true
      log_denies_enabled        = true
      mutation_enabled          = true

      policy_content {
        bundles {
          bundle_name         = "cis-k8s-v1.5.1"
          exempted_namespaces = []
        }
        bundles {
          bundle_name         = "pss-baseline-v2022"
          exempted_namespaces = []
        }
        bundles {
          bundle_name         = "pss-restricted-v2022"
          exempted_namespaces = []
        }
        template_library {
          installation = "ALL"
        }
      }

      monitoring {
        backends = ["CLOUD_MONITORING"]
      }
    }
  }
}
