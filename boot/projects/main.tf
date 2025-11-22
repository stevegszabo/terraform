terraform {
  cloud {
    organization = "organization"
    workspaces {
      name = "boot-projects"
    }
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.41.0"
    }
  }
}

provider "google" {
  project = local.gcp_instance_project
}

locals {
  gcp_instance_billing = "domain"
  gcp_instance_project = "boot-999999"
  gcp_instance_folder  = "999999999999"

  gcp_instance_common_services = [
    "anthos.googleapis.com",
    "anthosaudit.googleapis.com",
    "anthosgke.googleapis.com",
    "anthospolicycontroller.googleapis.com",
    "artifactregistry.googleapis.com",
    "binaryauthorization.googleapis.com",
    "cloudidentity.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "connectgateway.googleapis.com",
    "container.googleapis.com",
    "containeranalysis.googleapis.com",
    "containersecurity.googleapis.com",
    "firewallinsights.googleapis.com",
    "gkeconnect.googleapis.com",
    "gkehub.googleapis.com",
    "gkeonprem.googleapis.com",
    "iam.googleapis.com",
    "kubernetesmetadata.googleapis.com",
    "logging.googleapis.com",
    "mesh.googleapis.com",
    "monitoring.googleapis.com",
    "networkconnectivity.googleapis.com",
    "networkmanagement.googleapis.com",
    "opsconfigmonitoring.googleapis.com",
    "privateca.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "serviceusage.googleapis.com",
    "stackdriver.googleapis.com",
    "storage.googleapis.com"
  ]

  gcp_instance_projects = {
    project-01 = {
      owners   = []
      services = local.gcp_instance_common_services
    }
  }

  gcp_instance_services = [
    for index, value in local.gcp_instance_projects : [
      for service in distinct(value["services"]) : {
        project = index
        service = service
      }
    ]
  ]

  gcp_instance_owners = [
    for index, value in local.gcp_instance_projects : [
      for identity in distinct(value["owners"]) : {
        project  = index
        identity = identity
      }
    ]
  ]

  gcp_instance_services_map = {
    for index, value in flatten(local.gcp_instance_services) :
      format("%s-%s", value["project"], value["service"]) => value
  }

  gcp_instance_owners_map = {
    for index, value in flatten(local.gcp_instance_owners) :
      format("%s-%s", value["project"], value["identity"]) => value
  }
}

data "google_billing_account" "this" {
  display_name = local.gcp_instance_billing
  open         = true
}

resource "random_string" "this" {
  for_each = local.gcp_instance_projects
  length   = 6
  special  = false
}

resource "google_project" "this" {
  for_each            = local.gcp_instance_projects
  name                = each.key
  project_id          = format("%s-%s", each.key, lower(random_string.this[each.key].result))
  folder_id           = local.gcp_instance_folder
  billing_account     = data.google_billing_account.this.id
  auto_create_network = false
  deletion_policy     = "DELETE"
}

resource "google_project_service" "this" {
  for_each                   = local.gcp_instance_services_map
  project                    = google_project.this[each.value["project"]].id
  service                    = each.value["service"]
  disable_dependent_services = true
}

resource "google_project_iam_member" "this" {
  for_each = local.gcp_instance_owners_map
  project  = google_project.this[each.value["project"]].id
  role     = "roles/owner"
  member   = each.value["identity"]
}
