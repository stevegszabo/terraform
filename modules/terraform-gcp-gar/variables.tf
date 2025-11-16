variable "gcp_instance_project" {
  description = "gcp_instance_project"
  default     = "engineering-01"
  type        = string
}

variable "gcp_instance_region" {
  description = "gcp_instance_region"
  default     = "us-east1"
  type        = string
}

variable "gcp_instance_name" {
  description = "gcp_instance_name"
  default     = "engineering-00"
  type        = string
}

variable "gcp_instance_keyring" {
  description = "gcp_instance_keyring"
  default     = "engineering-00"
  type        = string
}

variable "gcp_instance_crypto_key" {
  description = "gcp_instance_crypto_key"
  default     = "engineering-00"
  type        = string
}
