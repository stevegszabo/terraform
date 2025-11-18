variable "gcp_instance_name" {
  description = "gcp_instance_name"
  default     = "default"
  type        = string
}

variable "gcp_instance_project" {
  description = "gcp_instance_project"
  default     = "default"
  type        = string
}

variable "gcp_instance_members" {
  description = "gcp_instance_members"
  default     = {}
  type = map(object({
    location         = string
    policycontroller = bool
    servicemesh      = bool
  }))
}
