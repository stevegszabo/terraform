locals {
  gcp_instance_name             = var.gcp_instance_name
  gcp_instance_project          = var.gcp_instance_project
  gcp_instance_create_dns_zone  = var.gcp_instance_create_dns_zone
  gcp_instance_zone             = var.gcp_instance_zone
  gcp_instance_domain           = var.gcp_instance_domain
  gcp_instance_exclude_cidrs    = var.gcp_instance_exclude_cidrs
  gcp_instance_subnets          = var.gcp_instance_subnets
  gcp_instance_firewall_rules   = var.gcp_instance_firewall_rules
  gcp_instance_psc_address      = var.gcp_instance_psc_address
  gcp_instance_psc_forward      = var.gcp_instance_psc_forward
  gcp_instance_dns_peer_vpcs    = var.gcp_instance_dns_peer_vpcs
  gcp_instance_dns_gke_clusters = var.gcp_instance_dns_gke_clusters
  gcp_instance_ncc_export_psc   = var.gcp_instance_ncc_export_psc
  gcp_instance_ncc_hub          = var.gcp_instance_ncc_hub
  gcp_instance_ncc_hub_id       = local.gcp_instance_ncc_hub != null ? local.gcp_instance_ncc_hub : google_network_connectivity_hub.this[0].id
  gcp_instance_private_nat      = length(local.gcp_instance_private_nat_subnet_links) > 0 ? true : false

  gcp_instance_dns_peer_vpcs_lst = flatten([
    for index, value in local.gcp_instance_dns_peer_vpcs : [
      for network in distinct(value) : {
        project = index
        network = network
      }
    ]
  ])

  gcp_instance_dns_peer_vpcs_map = {
    for index in flatten(local.gcp_instance_dns_peer_vpcs_lst) :
      format("%s-%s", index["project"], index["network"]) => index
  }

  # PRIVATE:         Subnets classified as PRIVATE will be non-routable over the ncc hub
  # PRIVATE_NAT:     Subnets classified as PRIVATE_NAT will be routable over the ncc hub
  # PRIVATE_INGRESS: Subnets classified as PRIVATE_INGRESS will be routable over the ncc hub

  # Subnets which are excluded from the ncc spoke
  gcp_instance_private_subnet_cidrs = flatten([
    for index, value in local.gcp_instance_subnets : value["cidr"] if value["purpose"] == "PRIVATE"
  ])

  # Subnets which utilize nat routing - cloud nat mapping
  gcp_instance_private_subnet_ids = [
    for index, value in local.gcp_instance_subnets : google_compute_subnetwork.this[index].id if value["purpose"] == "PRIVATE"
  ]

  # Subnets which provide nat routing - cloud nat rules
  gcp_instance_private_nat_subnet_links = [
    for index, value in local.gcp_instance_subnets : google_compute_subnetwork.this[index].self_link if value["purpose"] == "PRIVATE_NAT"
  ]
}

data "google_compute_network" "this" {
  for_each = local.gcp_instance_dns_peer_vpcs_map
  name     = each.value["network"]
  project  = each.value["project"]
}

data "google_container_cluster" "this" {
  for_each = toset(local.gcp_instance_dns_gke_clusters)
  project  = split("/", each.value)[1]
  location = split("/", each.value)[3]
  name     = split("/", each.value)[5]
}

resource "google_compute_network" "this" {
  name                    = local.gcp_instance_name
  auto_create_subnetworks = false
}

resource "google_dns_managed_zone" "this" {
  count       = local.gcp_instance_create_dns_zone ? 1 : 0
  name        = local.gcp_instance_zone
  description = local.gcp_instance_zone
  dns_name    = format("%s.%s.", local.gcp_instance_zone, local.gcp_instance_domain)
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.this.id
    }

    dynamic "gke_clusters" {
      for_each = local.gcp_instance_dns_gke_clusters

      content {
        gke_cluster_name = data.google_container_cluster.this[gke_clusters.value].id
      }
    }
  }

  dynamic "peering_config" {
    for_each = length(local.gcp_instance_dns_peer_vpcs_map) == 0 ? [] : [1]

    content {
      dynamic "target_network" {
        for_each = local.gcp_instance_dns_peer_vpcs_map

        content {
          network_url = data.google_compute_network.this[target_network.key].id
        }
      }
    }
  }
}

resource "google_compute_firewall" "this" {
  for_each           = local.gcp_instance_firewall_rules
  name               = each.key
  network            = google_compute_network.this.name
  direction          = each.value["direction"]
  source_ranges      = each.value["source_ranges"]
  destination_ranges = each.value["destination_ranges"]
  target_tags        = each.value["target_tags"]
  priority           = each.value["priority"]

  allow {
    protocol = each.value["protocol"]
    ports    = each.value["ports"]
  }
}

resource "google_compute_global_address" "this" {
  name         = local.gcp_instance_psc_forward
  address_type = "INTERNAL"
  purpose      = "PRIVATE_SERVICE_CONNECT"
  network      = google_compute_network.this.id
  address      = local.gcp_instance_psc_address
}

resource "google_compute_global_forwarding_rule" "this" {
  name                  = google_compute_global_address.this.name
  target                = "all-apis"
  network               = google_compute_network.this.id
  ip_address            = google_compute_global_address.this.id
  load_balancing_scheme = ""
}

resource "google_compute_subnetwork" "this" {
  for_each                 = local.gcp_instance_subnets
  network                  = google_compute_network.this.id
  name                     = each.key
  ip_cidr_range            = each.value["cidr"]
  purpose                  = each.value["purpose"] == "PRIVATE_INGRESS" ? "PRIVATE" : each.value["purpose"]
  private_ip_google_access = true
}

resource "google_compute_router" "this" {
  name     = local.gcp_instance_name
  network  = google_compute_network.this.name

  bgp {
    asn               = 64514
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }
}

resource "google_network_connectivity_hub" "this"  {
  count       = local.gcp_instance_ncc_hub == null ? 1 : 0
  name        = local.gcp_instance_name
  description = local.gcp_instance_name
  export_psc  = local.gcp_instance_ncc_export_psc
}

resource "google_network_connectivity_spoke" "this"  {
  name        = local.gcp_instance_project
  description = local.gcp_instance_project
  hub         = local.gcp_instance_ncc_hub_id
  location    = "global"

  linked_vpc_network {
    uri                   = google_compute_network.this.self_link
    exclude_export_ranges = concat(local.gcp_instance_private_subnet_cidrs, local.gcp_instance_exclude_cidrs)
  }
}

resource "google_compute_router_nat" "this" {
  provider                            = google-beta
  name                                = local.gcp_instance_name
  router                              = google_compute_router.this.name
  source_subnetwork_ip_ranges_to_nat  = "LIST_OF_SUBNETWORKS"
  type                                = local.gcp_instance_private_nat ? "PRIVATE" : "PUBLIC"
  nat_ip_allocate_option              = local.gcp_instance_private_nat ? null : "AUTO_ONLY"
  depends_on                          = [google_network_connectivity_spoke.this]

  dynamic "subnetwork" {
    for_each = local.gcp_instance_private_subnet_ids

    content {
      name                    = subnetwork.value
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }

  dynamic "rules" {
    for_each = local.gcp_instance_private_nat ? [1] : []

    content {
      rule_number = 100
      description = local.gcp_instance_name
      match       = format("nexthop.hub == '//networkconnectivity.googleapis.com/%s'", local.gcp_instance_ncc_hub_id)

      action {
        source_nat_active_ranges = local.gcp_instance_private_nat_subnet_links
      }
    }
  }
}
