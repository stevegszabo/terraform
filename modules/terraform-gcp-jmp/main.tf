locals {
  gcp_instance_environment  = var.gcp_instance_environment
  gcp_instance_sa_roles     = var.gcp_instance_sa_roles
  gcp_instance_machine_type = var.gcp_instance_machine_type
  gcp_instance_project      = var.gcp_instance_project
  gcp_instance_project_pub  = var.gcp_instance_project_pub
  gcp_instance_subnet       = var.gcp_instance_subnet
  gcp_instance_name         = var.gcp_instance_name
  gcp_instance_zone         = var.gcp_instance_zone
  gcp_instance_dns_pri_zone = var.gcp_instance_dns_pri_zone
  gcp_instance_dns_pub_zone = var.gcp_instance_dns_pub_zone
  gcp_instance_disk_image   = var.gcp_instance_disk_image
  gcp_instance_secret_key   = var.gcp_instance_secret_key
  gcp_instance_network_tags = var.gcp_instance_network_tags

  gcp_instance_cloud_init   = file("cloud-init.sh")
  gcp_instance_ssh_keys     = format("ubuntu:%s", data.google_secret_manager_secret_version.this.secret_data)
  gcp_instance_network_tier = "STANDARD"
  gcp_instance_disk_type    = "pd-standard"
  gcp_instance_disk_size    = 10

  gcp_instance_access = [
    for index, value in local.gcp_instance_sa_roles : [
      for role in value : {
        project = index
        role    = role
      }
    ]
  ]

  gcp_instance_sa_access_map = {
    for index, value in flatten(local.gcp_instance_access) :
      format("%s-%s", value["project"], value["role"]) => value
  }
}

data "google_secret_manager_secret_version" "this" {
  secret = local.gcp_instance_secret_key
}

data "google_compute_subnetwork" "this" {
  name   = local.gcp_instance_subnet
}

data "google_dns_managed_zone" "this" {
  name    = local.gcp_instance_dns_pub_zone
  project = local.gcp_instance_project_pub
}

resource "google_service_account" "this" {
  account_id   = local.gcp_instance_name
  display_name = local.gcp_instance_name
}

resource "google_project_iam_member" "this" {
  for_each = local.gcp_instance_sa_access_map
  project  = each.value["project"]
  role     = each.value["role"]
  member   = format("serviceAccount:%s", google_service_account.this.email)
}

resource "google_dns_record_set" "this" {
  managed_zone = data.google_dns_managed_zone.this.name
  project      = data.google_dns_managed_zone.this.project
  name         = format("%s.%s", local.gcp_instance_name, data.google_dns_managed_zone.this.dns_name)
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_instance.this.network_interface[0].access_config[0].nat_ip]
}

resource "google_compute_address" "this" {
  name         = local.gcp_instance_name
  network_tier = local.gcp_instance_network_tier
  address_type = "EXTERNAL"
}

resource "google_compute_instance" "this" {
  name                = local.gcp_instance_name
  zone                = local.gcp_instance_zone
  machine_type        = local.gcp_instance_machine_type
  tags                = local.gcp_instance_network_tags
  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    environment = local.gcp_instance_environment
  }

  metadata = {
    ssh-keys  = local.gcp_instance_ssh_keys
    user-data = local.gcp_instance_cloud_init
  }

  service_account {
    email  = google_service_account.this.email
    scopes = ["cloud-platform"]
  }

  boot_disk {
    device_name = local.gcp_instance_name
    mode        = "READ_WRITE"
    auto_delete = true

    initialize_params {
      type  = local.gcp_instance_disk_type
      image = local.gcp_instance_disk_image
      size  = local.gcp_instance_disk_size
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.this.id

    access_config {
      network_tier = local.gcp_instance_network_tier
      nat_ip       = google_compute_address.this.address
    }
  }

  scheduling {
    preemptible                 = true
    automatic_restart           = false
    provisioning_model          = "SPOT"
    on_host_maintenance         = "TERMINATE"
    instance_termination_action = "STOP"
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_vtpm                 = true
    enable_secure_boot          = false
  }
}
