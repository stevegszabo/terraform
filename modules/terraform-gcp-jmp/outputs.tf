output "gcp_instance_public_dns" {
  value = google_dns_record_set.this.name
}
