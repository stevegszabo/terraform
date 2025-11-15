locals {
  gcp_instance_region          = var.gcp_instance_region
  gcp_instance_zone            = var.gcp_instance_zone
  gcp_instance_project         = var.gcp_instance_project
  gcp_instance_name            = var.gcp_instance_name
  gcp_instance_environment     = var.gcp_instance_environment
  gcp_instance_keyring         = var.gcp_instance_keyring
  gcp_instance_crypto_key      = var.gcp_instance_crypto_key
  gcp_instance_service_account = var.gcp_instance_service_account
  gcp_instance_network_vpc     = var.gcp_instance_network_vpc
  gcp_instance_network_subnet  = var.gcp_instance_network_subnet
  gcp_instance_version         = var.gcp_instance_version
  gcp_instance_pod_cidr        = var.gcp_instance_pod_cidr
  gcp_instance_svc_cidr        = var.gcp_instance_svc_cidr
  gcp_instance_pep_cidr        = var.gcp_instance_pep_cidr
  gcp_instance_binary_auth     = var.gcp_instance_binary_auth
  gcp_instance_logging         = var.gcp_instance_logging
  gcp_instance_monitoring      = var.gcp_instance_monitoring
  gcp_instance_encryption      = var.gcp_instance_encryption
  gcp_instance_worker_pools    = var.gcp_instance_worker_pools
  gcp_instance_auto_provision  = var.gcp_instance_auto_provision
  gcp_instance_private_nodes   = var.gcp_instance_private_nodes
  gcp_instance_private_api     = var.gcp_instance_private_api
  gcp_instance_http_balancing  = var.gcp_instance_http_balancing
  gcp_instance_config_connect  = var.gcp_instance_config_connect
  gcp_instance_api_access      = var.gcp_instance_api_access
  gcp_instance_accounts        = var.gcp_instance_accounts
  gcp_instance_security_group  = var.gcp_instance_security_group

  gcp_instance_roles = [
    for index, value in local.gcp_instance_accounts : [
      for role in distinct(value["project_roles"]) : [
        for project in distinct(value["projects"]) : {
          project = project
          account = index
          role    = role
        }
      ]
    ]
  ]

  gcp_instance_roles_map = {
    for index, value in flatten(local.gcp_instance_roles) :
      format("%s-%s-%s", value["project"], value["account"], value["role"]) => value
  }
}

data "google_project" "this" {
  project_id = local.gcp_instance_project
}

data "google_service_account" "this" {
  account_id = local.gcp_instance_service_account
  depends_on = [google_service_account.this]
}

data "google_compute_network" "this" {
  name = local.gcp_instance_network_vpc
}

data "google_compute_subnetwork" "this" {
  name   = local.gcp_instance_network_subnet
  region = local.gcp_instance_region
}

data "google_kms_key_ring" "this" {
  count    = local.gcp_instance_encryption ? 1 : 0
  name     = local.gcp_instance_keyring
  location = local.gcp_instance_region
}

data "google_kms_crypto_key" "this" {
  count    = local.gcp_instance_encryption ? 1 : 0
  name     = local.gcp_instance_crypto_key
  key_ring = data.google_kms_key_ring.this[count.index].id
}

resource "google_kms_crypto_key_iam_member" "compute" {
  count         = local.gcp_instance_encryption ? 1 : 0
  crypto_key_id = data.google_kms_crypto_key.this[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = format("serviceAccount:service-%s@compute-system.iam.gserviceaccount.com", data.google_project.this.number)
}

resource "google_kms_crypto_key_iam_member" "container" {
  count         = local.gcp_instance_encryption ? 1 : 0
  crypto_key_id = data.google_kms_crypto_key.this[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = format("serviceAccount:service-%s@container-engine-robot.iam.gserviceaccount.com", data.google_project.this.number)
}

resource "google_service_account" "this" {
  for_each     = local.gcp_instance_accounts
  account_id   = each.key
  display_name = each.key
}

resource "google_service_account_iam_binding" "this" {
  for_each           = local.gcp_instance_accounts
  service_account_id = google_service_account.this[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  members            = each.value["kube_svc_accounts"]
}

resource "google_project_iam_member" "this" {
  for_each = local.gcp_instance_roles_map
  project  = each.value["project"]
  role     = each.value["role"]
  member   = format("serviceAccount:%s", google_service_account.this[each.value["account"]].email)
}

resource "google_container_cluster" "this" {
  provider                 = google-beta
  name                     = local.gcp_instance_name
  location                 = local.gcp_instance_zone != null ? local.gcp_instance_zone : local.gcp_instance_region
  min_master_version       = local.gcp_instance_version
  network                  = data.google_compute_network.this.name
  subnetwork               = data.google_compute_subnetwork.this.name
  datapath_provider        = "ADVANCED_DATAPATH"
  remove_default_node_pool = true
  deletion_protection      = false
  initial_node_count       = 1

  depends_on = [
    google_service_account.this,
    google_service_account_iam_binding.this,
    google_project_iam_member.this,
    google_kms_crypto_key_iam_member.compute,
    google_kms_crypto_key_iam_member.container
  ]

  resource_labels = {
    environment = local.gcp_instance_environment
  }

  authenticator_groups_config {
    security_group = local.gcp_instance_security_group
  }

  dns_config {
    cluster_dns       = "CLOUD_DNS"
    cluster_dns_scope = "CLUSTER_SCOPE"
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }

  release_channel {
    channel = "STABLE"
  }

  protect_config {
    workload_config {
      audit_mode = "BASIC"
    }
    workload_vulnerability_mode = "BASIC"
  }

  security_posture_config {
    vulnerability_mode = "VULNERABILITY_BASIC"
    mode               = "BASIC"
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "00:00"
    }
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = local.gcp_instance_pod_cidr
    services_ipv4_cidr_block = local.gcp_instance_svc_cidr
  }

  master_authorized_networks_config {
    gcp_public_cidrs_access_enabled = false

    dynamic "cidr_blocks" {
      for_each = local.gcp_instance_api_access

      content {
        cidr_block = cidr_blocks.value
      }
    }
  }

  private_cluster_config {
    enable_private_nodes    = local.gcp_instance_private_nodes
    enable_private_endpoint = local.gcp_instance_private_api
    master_ipv4_cidr_block  = local.gcp_instance_pep_cidr

    master_global_access_config {
      enabled = true
    }
  }

  control_plane_endpoints_config {
    dns_endpoint_config {
      allow_external_traffic = true
    }
  }

  addons_config {
    http_load_balancing {
      disabled = ! local.gcp_instance_http_balancing
    }

    config_connector_config {
      enabled = local.gcp_instance_config_connect
    }
  }

  workload_identity_config {
    workload_pool = format("%s.svc.id.goog", local.gcp_instance_project)
  }

  dynamic "binary_authorization" {
    for_each = local.gcp_instance_binary_auth ? [0] : []

    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
    }
  }

  dynamic "database_encryption" {
    for_each = local.gcp_instance_encryption ? [0] : []

    content {
      state    = "ENCRYPTED"
      key_name = data.google_kms_crypto_key.this[0].id
    }
  }

  dynamic "logging_config" {
    for_each = local.gcp_instance_logging ? [0] : []

    content {
      enable_components = [
        "SYSTEM_COMPONENTS",
        "APISERVER",
        "CONTROLLER_MANAGER",
        "SCHEDULER",
        "WORKLOADS"
      ]
    }
  }

  dynamic "monitoring_config" {
    for_each = local.gcp_instance_monitoring ? [0] : []

    content {
      enable_components = [
        "SYSTEM_COMPONENTS",
        "APISERVER",
        "SCHEDULER",
        "CONTROLLER_MANAGER",
        "STORAGE",
        "HPA",
        "POD",
        "DAEMONSET",
        "DEPLOYMENT",
        "STATEFULSET",
        "KUBELET",
        "CADVISOR",
        "DCGM",
        "JOBSET"
      ]
    }
  }

  dynamic "cluster_autoscaling" {
    for_each = local.gcp_instance_auto_provision ? [0] : []

    content {
      enabled = true

      resource_limits {
        resource_type = "cpu"
        maximum       = 16
      }

      resource_limits {
        resource_type = "memory"
        maximum       = 32
      }

      auto_provisioning_defaults {
        service_account   = data.google_service_account.this.email
        boot_disk_kms_key = local.gcp_instance_encryption ? data.google_kms_crypto_key.this[0].id : null
        oauth_scopes      = ["https://www.googleapis.com/auth/cloud-platform"]
        disk_size         = 25
        disk_type         = "pd-standard"
        image_type        = "COS_CONTAINERD"

        management {
          auto_upgrade = true
          auto_repair  = true
        }

        upgrade_settings {
          max_unavailable = 1
          max_surge       = 3
          strategy        = "SURGE"
        }
      }
    }
  }
}

resource "google_container_node_pool" "this" {
  for_each           = local.gcp_instance_worker_pools
  name               = each.key
  location           = local.gcp_instance_zone != null ? local.gcp_instance_zone : local.gcp_instance_region
  cluster            = google_container_cluster.this.id
  initial_node_count = 1

  depends_on = [
    google_service_account.this,
    google_service_account_iam_binding.this,
    google_project_iam_member.this,
    google_kms_crypto_key_iam_member.compute,
    google_kms_crypto_key_iam_member.container
  ]

  lifecycle {
    ignore_changes = [
      initial_node_count,
      node_config[0].resource_labels
    ]
  }

  autoscaling {
    min_node_count  = each.value["autoscale_min_nodes"]
    max_node_count  = each.value["autoscale_max_nodes"]
    location_policy = "BALANCED"
  }

  management {
    auto_upgrade = true
    auto_repair  = true
  }

  upgrade_settings {
    max_unavailable = 1
    max_surge       = 3
    strategy        = "SURGE"
  }

  node_config {
    service_account   = data.google_service_account.this.email
    boot_disk_kms_key = local.gcp_instance_encryption ? data.google_kms_crypto_key.this[0].id : null
    oauth_scopes      = ["https://www.googleapis.com/auth/cloud-platform"]
    machine_type      = each.value["machine_type"]
    disk_type         = each.value["machine_disk_type"]
    disk_size_gb      = each.value["machine_disk_size"]
    preemptible       = each.value["machine_preemptible"]
    labels            = each.value["node_labels"]

    dynamic "taint" {
      for_each = each.value["node_taints"]

      content {
        key    = taint.value["key"]
        value  = taint.value["value"]
        effect = taint.value["effect"]
      }
    }
  }
}
