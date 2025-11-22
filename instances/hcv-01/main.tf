terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.12.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "4.6.0"
    }
  }
}

provider "google" {
  project = local.gcp_instance_project
  region  = local.gcp_instance_region
}

provider "vault" {
  address         = local.gcp_instance_vault
  token           = jsondecode(data.google_secret_manager_secret_version.this.secret_data)["root"]
  skip_tls_verify = true
}

locals {
  gcp_instance_project = "project-01-xxxxxx"
  gcp_instance_region  = "northamerica-northeast2"
  gcp_instance_access  = "gke-01-hcv"
  gcp_instance_vault   = "http://127.0.0.1:8200/"
  gcp_instance_mounts  = ["webapp-engine"]

  gcp_instance_clusters = {
    project-01-xxxxxx = [
      {
        cluster  = "gke-01"
        region   = "northamerica-northeast2"
        policies = [
          {
            name   = "webapp"
            policy = file("policies/webapp-policy.hcl")
          }
        ]
        roles = [
          {
            name       = "webapp"
            namespaces = ["app-01"]
            accounts   = ["webapp"]
            policies   = ["webapp"]
            ttl        = 3600
          }
        ]
        secrets = [
          {
            name  = "webapp-secret"
            mount = "webapp-engine"
            data  = file("secrets/webapp-secret.json")
          }
        ]
      }
    ]
  }

  gcp_instance_clusters_lst = [
    for project, clusters in local.gcp_instance_clusters : [
      for cluster in distinct(clusters) : {
        project  = project
        region   = cluster["region"]
        cluster  = cluster["cluster"]
        secrets  = cluster["secrets"]
        policies = cluster["policies"]
        roles    = cluster["roles"]
        path     = format("%s/%s", project, cluster["cluster"])
      }
    ]
  ]

  gcp_instance_clusters_map = {
    for cluster in flatten(local.gcp_instance_clusters_lst) :
      format("%s_%s", cluster["project"], cluster["cluster"]) => cluster
  }

  gcp_instance_policies = [
    for cluster in flatten(local.gcp_instance_clusters_lst) : {
      for policy in distinct(cluster["policies"]) :
        format("%s_%s_%s", cluster["project"], cluster["cluster"], policy["name"]) => policy
    }
  ]

  gcp_instance_roles = [
    for cluster in flatten(local.gcp_instance_clusters_lst) : {
      for role in distinct(cluster["roles"]) :
        format("%s_%s_%s", cluster["project"], cluster["cluster"], role["name"]) => role
    }
  ]

  gcp_instance_secrets = [
    for cluster in flatten(local.gcp_instance_clusters_lst) : {
      for secret in distinct(cluster["secrets"]) :
        format("%s_%s_%s", cluster["project"], cluster["cluster"], secret["name"]) => secret
    }
  ]
}

data "google_secret_manager_secret_version" "this" {
  secret = local.gcp_instance_access
}

data "google_container_cluster" "this" {
  for_each = local.gcp_instance_clusters_map
  name     = each.value["cluster"]
  project  = each.value["project"]
}

resource "vault_auth_backend" "this" {
  for_each = local.gcp_instance_clusters_map
  type     = "kubernetes"
  path     = each.value["path"]
}

resource "vault_kubernetes_auth_backend_config" "this" {
  for_each        = local.gcp_instance_clusters_map
  backend         = vault_auth_backend.this[each.key].path
  kubernetes_host = format("https://%s", data.google_container_cluster.this[each.key].endpoint)
}

resource "vault_mount" "this" {
  for_each = toset(local.gcp_instance_mounts)
  path     = each.value
  type     = "kv"
  options  = {
    version = "2"
  }
}

resource "vault_policy" "this" {
  for_each = local.gcp_instance_policies[0]
  name     = each.value["name"]
  policy   = each.value["policy"]
}

resource "vault_kv_secret_v2" "this" {
  for_each   = local.gcp_instance_secrets[0]
  depends_on = [vault_mount.this]
  name       = each.value["name"]
  mount      = each.value["mount"]
  data_json  = each.value["data"]
}

resource "vault_kubernetes_auth_backend_role" "this" {
  for_each                         = local.gcp_instance_roles[0]
  depends_on                       = [vault_auth_backend.this, vault_policy.this]
  backend                          = format("%s/%s", split("_", each.key)[0], split("_", each.key)[1])
  role_name                        = each.value["name"]
  bound_service_account_names      = each.value["accounts"]
  bound_service_account_namespaces = each.value["namespaces"]
  token_policies                   = each.value["policies"]
  token_ttl                        = each.value["ttl"]
}
