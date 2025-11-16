variable "gcp_instance_region" {
  description = "gcp_instance_region"
  default     = "us-east1"
  type        = string
}

variable "gcp_instance_images" {
  description = "gcp_instance_images"
  default     = []
  type        = list(string)
}

variable "gcp_instance_clusters" {
  description = "gcp_instance_clusters"
  default     = []
  type        = list(object({
    cluster   = string
    keyring   = string
    cryptokey = string
  }))
}
