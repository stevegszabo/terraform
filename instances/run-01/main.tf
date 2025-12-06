terraform {
  cloud {
    organization = "organization"
    workspaces {
      name = "project-01-xxxxxx-run-01"
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
  region  = local.gcp_instance_region
}

locals {
  gcp_instance_project      = "project-01-xxxxxx"
  gcp_instance_region       = "northamerica-northeast2"
  gcp_instance_image        = format("%s-docker.pkg.dev/%s/gar-01/xxxxxxxxxx/webapp:v1.1.2", local.gcp_instance_region, local.gcp_instance_project)
  gcp_instance_account      = format("jump-eng-project-01@%s.iam.gserviceaccount.com", local.gcp_instance_project)
  gcp_instance_network      = "vpc-01"
  gcp_instance_subnetwork   = "vpc-01-subnet-01"
  gcp_instance_ingress_type = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
}

resource "google_cloud_run_v2_service_iam_member" "this" {
  name     = google_cloud_run_v2_service.this.name
  location = google_cloud_run_v2_service.this.location
  role     = "roles/run.invoker"
  member   = format("serviceAccount:%s", local.gcp_instance_account)
}

resource "google_cloud_run_v2_service" "this" {
  name                = "webapp"
  location            = local.gcp_instance_region
  ingress             = local.gcp_instance_ingress_type
  deletion_protection = false

  binary_authorization {
    use_default = true
  }

  template {
    timeout = "15s"
    max_instance_request_concurrency = 10

    scaling {
      max_instance_count = 3
    }

    vpc_access {
      network_interfaces {
        network    = local.gcp_instance_network
        subnetwork = local.gcp_instance_subnetwork
      }
    }

    containers {
      image = local.gcp_instance_image

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      env {
        name  = "WEBAPP_DATABASE"
        value = "santacruz"
      }

      env {
        name  = "WEBAPP_VERSION"
        value = "v1.0.0"
      }

      liveness_probe {
        initial_delay_seconds = 5
        failure_threshold     = 3
        timeout_seconds       = 3
        period_seconds        = 5

        http_get {
          path = "/"
        }
      }
    }
  }
}
