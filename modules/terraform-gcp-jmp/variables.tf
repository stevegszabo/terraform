variable "gcp_instance_name" {
  description = "gcp_instance_name"
  default     = "default"
  type        = string
}

variable "gcp_instance_environment" {
  description = "gcp_instance_environment"
  default     = "default"
  type        = string
}

variable "gcp_instance_sa_roles" {
  description = "gcp_instance_sa_roles"
  default     = {}
  type        = map(list(string))
}

variable "gcp_instance_machine_type" {
  description = "gcp_instance_machine_type"
  default     = "default"
  type        = string
}

variable "gcp_instance_project" {
  description = "gcp_instance_project"
  default     = "default"
  type        = string
}

variable "gcp_instance_project_pub" {
  description = "gcp_instance_project_pub"
  default     = "default"
  type        = string
}

variable "gcp_instance_subnet" {
  description = "gcp_instance_subnet"
  default     = "default"
  type        = string
}

variable "gcp_instance_zone" {
  description = "gcp_instance_zone"
  default     = "default"
  type        = string
}

variable "gcp_instance_dns_pri_zone" {
  description = "gcp_instance_dns_pri_zone"
  default     = "default"
  type        = string
}

variable "gcp_instance_dns_pub_zone" {
  description = "gcp_instance_dns_pub_zone"
  default     = "default"
  type        = string
}

variable "gcp_instance_secret_key" {
  description = "gcp_instance_secret_key"
  default     = "default"
  type        = string
}

variable "gcp_instance_disk_image" {
  description = "gcp_instance_disk_image"
  default     = "default"
  type        = string
}

variable "gcp_instance_network_tags" {
  description = "gcp_instance_network_tags"
  default     = []
  type        = list(string)
}
