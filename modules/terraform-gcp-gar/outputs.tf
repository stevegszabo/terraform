output "gcp_instance_registry_url" {
  value = format("%s-docker.pkg.dev/%s/%s",
    google_artifact_registry_repository.this.location,
    google_artifact_registry_repository.this.project,
    google_artifact_registry_repository.this.repository_id)
}
