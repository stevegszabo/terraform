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

variable "gcp_instance_create_dns_zone" {
  description = "gcp_instance_create_dns_zone"
  default     = false
  type        = bool
}

variable "gcp_instance_zone" {
  description = "gcp_instance_zone"
  default     = "default"
  type        = string
}

variable "gcp_instance_domain" {
  description = "gcp_instance_domain"
  default     = "default"
  type        = string
}

variable "gcp_instance_allow_cidrs" {
  description = "gcp_instance_allow_cidrs"
  default     = []
  type        = list(string)
}

variable "gcp_instance_exclude_cidrs" {
  description = "gcp_instance_exclude_cidrs"
  default     = []
  type        = list(string)
}

variable "gcp_instance_firewall_rules" {
  description = "gcp_instance_firewall_rules"
  default     = {}
  type = map(object({
    direction          = string
    source_ranges      = list(string)
    destination_ranges = list(string)
    target_tags        = list(string)
    priority           = number
    protocol           = string
    ports              = list(string)
  }))
}

variable "gcp_instance_subnets" {
  description = "gcp_instance_subnets"
  default     = {}
  type = map(object({
    cidr    = string
    purpose = optional(string, "PRIVATE")
  }))
  validation {
    condition     = alltrue([for subnet in values(var.gcp_instance_subnets): contains(["PRIVATE", "PRIVATE_NAT", "PRIVATE_INGRESS"], subnet.purpose)])
    error_message = "Subnet purpose must be one of: 'PRIVATE', 'PRIVATE_NAT', 'PRIVATE_INGRESS'"
  }
}

variable "gcp_instance_ncc_hub" {
  description = "gcp_instance_ncc_hub"
  default     = null
  type        = string
}

variable "gcp_instance_ncc_export_psc" {
  description = "gcp_instance_ncc_export_psc"
  default     = false
  type        = bool
}

variable "gcp_instance_dns_peer_vpcs" {
  description = "gcp_instance_dns_peer_vpcs"
  default     = {}
  type        = map(list(string))
}

variable "gcp_instance_dns_gke_clusters" {
  description = "gcp_instance_dns_gke_clusters"
  default     = []
  type        = list(string)
}

variable "gcp_instance_psc_address" {
  description = "gcp_instance_psc_address"
  default     = "192.168.0.10"
  type        = string
}

variable "gcp_instance_psc_forward" {
  description = "gcp_instance_psc_forward"
  default     = "eng"
  type        = string
}
