output "gcp_instance_billing_account" {
  value = format("%s[%s]", data.google_billing_account.this.display_name, data.google_billing_account.this.id)
}

output "gcp_instance_projects" {
  value = { for index, value in local.gcp_instance_projects : google_project.this[index].project_id => google_project.this[index].number }
}
