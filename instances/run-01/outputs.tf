output "gcp_instance_uri" {
  value = google_cloud_run_v2_service.this.uri
}
