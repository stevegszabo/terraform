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

variable "gcp_instance_common_images" {
  description = "gcp_instance_common_images"
  default     = []
  type        = list(string)
}

variable "gcp_instance_clusters" {
  description = "gcp_instance_clusters"
  default     = {}
  type = map(object({
    keyring   = string
    cryptokey = string
    images    = list(string)
  }))
}
