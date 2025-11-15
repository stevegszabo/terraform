output "google_network_connectivity_hub" {
  value = local.gcp_instance_ncc_hub == null ? google_network_connectivity_hub.this[0].id : local.gcp_instance_ncc_hub
}
