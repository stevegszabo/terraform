terraform {
  cloud {
    organization = "organization"
    workspaces {
      name = "boot-workspaces"
    }
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.41.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.67.1"
    }
  }
}

provider "google" {
  project = local.gcp_instance_project
}

provider "tfe" {
  hostname = local.gcp_instance_tfe_hostname
}

locals {
  gcp_instance_project      = "boot-999999"
  gcp_instance_name         = format("eng-pool-%s", lower(random_string.this.result))

  gcp_instance_tfe_issuer   = format("https://%s", local.gcp_instance_tfe_hostname)
  gcp_instance_tfe_hostname = "app.terraform.io"
  gcp_instance_tfe_org      = "domain"
  gcp_instance_tfe_pool     = "domain"
  gcp_instance_tfe_project  = "engineering"

  gcp_instance_boot_roles = [
    "roles/dns.admin",
    "roles/resourcemanager.projectIamAdmin"
  ]

  gcp_instance_common_roles = [
    "roles/artifactregistry.admin",
    "roles/binaryauthorization.attestorsAdmin",
    "roles/binaryauthorization.policyAdmin",
    "roles/cloudkms.admin",
    "roles/cloudkms.cryptoOperator",
    "roles/compute.instanceAdmin.v1",
    "roles/compute.networkAdmin",
    "roles/compute.securityAdmin",
    "roles/container.admin",
    "roles/container.developer",
    "roles/container.clusterAdmin",
    "roles/containeranalysis.admin",
    "roles/dns.admin",
    "roles/firebasemods.serviceAgent",
    "roles/gkehub.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/networkconnectivity.hubAdmin",
    "roles/privateca.admin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/run.developer",
    "roles/secretmanager.secretAccessor",
    "roles/secretmanager.secretVersionManager",
    "roles/servicedirectory.editor",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/storage.admin"
  ]

  gcp_instance_projects = {
    project-01-xxxxxx = {
      roles      = local.gcp_instance_common_roles
      workspaces = [
        "arg-01",
        "bin-01",
        "cas-01",
        "gar-01",
        "gcs-01",
        "gke-01",
        "hub-01",
        "jmp-01",
        "kms-01",
        "vpc-01"
      ]
    }
  }

  gcp_instance_workspaces = [
    for index, value in local.gcp_instance_projects : [
      for workspace in distinct(value["workspaces"]) : {
        project   = index
        workspace = format("%s-%s", index, workspace)
      }
    ]
  ]

  gcp_instance_project_roles = [
    for index, value in local.gcp_instance_projects : [
      for role in distinct(value["roles"]) : {
        project = index
        role    = role
      }
    ]
  ]

  gcp_instance_workspaces_map = {
    for index, value in flatten(local.gcp_instance_workspaces) :
      value["workspace"] => value
  }

  gcp_instance_project_roles_map = {
    for index, value in flatten(local.gcp_instance_project_roles) :
      format("%s-%s", value["project"], value["role"]) => value
  }
}

data "tfe_project" "this" {
  name         = local.gcp_instance_tfe_project
  organization = local.gcp_instance_tfe_org
}

data "tfe_agent_pool" "this" {
  name          = local.gcp_instance_tfe_pool
  organization  = local.gcp_instance_tfe_org
}

resource "random_string" "this" {
  length  = 6
  special = false
}

resource "tfe_workspace" "this" {
  for_each     = local.gcp_instance_workspaces_map
  name         = each.value["workspace"]
  organization = local.gcp_instance_tfe_org
  project_id   = data.tfe_project.this.id
}

resource "tfe_workspace_settings" "this" {
  for_each       = local.gcp_instance_workspaces_map
  workspace_id   = tfe_workspace.this[each.key].id
  agent_pool_id  = data.tfe_agent_pool.this.id
  execution_mode = "agent"
}

resource "tfe_variable" "auth" {
  for_each     = local.gcp_instance_workspaces_map
  workspace_id = tfe_workspace.this[each.key].id
  key          = "TFC_GCP_PROVIDER_AUTH"
  value        = "true"
  category     = "env"
}

resource "tfe_variable" "name" {
  for_each     = local.gcp_instance_workspaces_map
  workspace_id = tfe_workspace.this[each.key].id
  key          = "TFC_GCP_WORKLOAD_PROVIDER_NAME"
  value        = google_iam_workload_identity_pool_provider.this[each.key].name
  category     = "env"
}

resource "tfe_variable" "account" {
  for_each     = local.gcp_instance_workspaces_map
  workspace_id = tfe_workspace.this[each.key].id
  key          = "TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL"
  value        = google_service_account.this.email
  category     = "env"
}

resource "google_service_account" "this" {
  account_id   = local.gcp_instance_name
  display_name = local.gcp_instance_name
}

resource "google_service_account_iam_member" "this" {
  service_account_id = google_service_account.this.name
  role               = "roles/iam.workloadIdentityUser"
  member             = format("principalSet://iam.googleapis.com/%s/*", google_iam_workload_identity_pool.this.name)
}

resource "google_project_iam_member" "project" {
  for_each = local.gcp_instance_project_roles_map
  project  = each.value["project"]
  role     = each.value["role"]
  member   = format("serviceAccount:%s", google_service_account.this.email)
}

resource "google_project_iam_member" "boot" {
  for_each = toset(local.gcp_instance_boot_roles)
  project  = local.gcp_instance_project
  role     = each.value
  member   = format("serviceAccount:%s", google_service_account.this.email)
}

resource "google_iam_workload_identity_pool" "this" {
  workload_identity_pool_id = local.gcp_instance_name
}

resource "google_iam_workload_identity_pool_provider" "this" {
  for_each                           = local.gcp_instance_workspaces_map
  workload_identity_pool_id          = google_iam_workload_identity_pool.this.workload_identity_pool_id
  workload_identity_pool_provider_id = each.value["workspace"]

  attribute_mapping = {
    "google.subject"                        = "assertion.sub",
    "attribute.aud"                         = "assertion.aud",
    "attribute.terraform_run_phase"         = "assertion.terraform_run_phase",
    "attribute.terraform_run_id"            = "assertion.terraform_run_id",
    "attribute.terraform_project_id"        = "assertion.terraform_project_id",
    "attribute.terraform_project_name"      = "assertion.terraform_project_name",
    "attribute.terraform_workspace_id"      = "assertion.terraform_workspace_id",
    "attribute.terraform_workspace_name"    = "assertion.terraform_workspace_name",
    "attribute.terraform_full_workspace"    = "assertion.terraform_full_workspace",
    "attribute.terraform_organization_id"   = "assertion.terraform_organization_id",
    "attribute.terraform_organization_name" = "assertion.terraform_organization_name"
  }

  oidc {
    issuer_uri = local.gcp_instance_tfe_issuer
  }

  attribute_condition = format("assertion.sub.startsWith('organization:%s:project:%s:workspace:%s')",
    local.gcp_instance_tfe_org,
    local.gcp_instance_tfe_project,
    each.value["workspace"])
}
