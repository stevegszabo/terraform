variable "gcp_instance_region" {
  description = "gcp_instance_region"
  default     = "us-east1"
  type        = string
}

variable "gcp_instance_zone" {
  description = "gcp_instance_zone"
  default     = null
  type        = string
}

variable "gcp_instance_project" {
  description = "gcp_instance_project"
  default     = "engineering-000000"
  type        = string
}

variable "gcp_instance_name" {
  description = "gcp_instance_name"
  default     = "engineering-00"
  type        = string
}

variable "gcp_instance_environment" {
  description = "gcp_instance_environment"
  default     = "engineering"
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

variable "gcp_instance_service_account" {
  description = "gcp_instance_service_account"
  default     = "engineering-00"
  type        = string
}

variable "gcp_instance_network_vpc" {
  description = "gcp_instance_network_vpc"
  default     = "engineering-00"
  type        = string
}

variable "gcp_instance_network_subnet" {
  description = "gcp_instance_network_subnet"
  default     = "engineering-00"
  type        = string
}

variable "gcp_instance_version" {
  description = "gcp_instance_version"
  default     = "1.28.9"
  type        = string
}

variable "gcp_instance_pod_cidr" {
  description = "gcp_instance_pod_cidr"
  default     = null
  type        = string
}

variable "gcp_instance_svc_cidr" {
  description = "gcp_instance_svc_cidr"
  default     = null
  type        = string
}

variable "gcp_instance_pep_cidr" {
  description = "gcp_instance_pep_cidr"
  default     = null
  type        = string
}

variable "gcp_instance_binary_auth" {
  description = "gcp_instance_binary_auth"
  default     = false
  type        = bool
}

variable "gcp_instance_logging" {
  description = "gcp_instance_logging"
  default     = false
  type        = bool
}

variable "gcp_instance_monitoring" {
  description = "gcp_instance_monitoring"
  default     = false
  type        = bool
}

variable "gcp_instance_encryption" {
  description = "gcp_instance_encryption"
  default     = false
  type        = bool
}

variable "gcp_instance_worker_pools" {
  description = "gcp_instance_worker_pools"
  default     = {}
  type        = map(object({
    machine_type        = string
    machine_disk_type   = string
    machine_disk_size   = number
    machine_preemptible = bool
    autoscale_min_nodes = number
    autoscale_max_nodes = number
    node_labels         = map(string)
    node_taints         = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
}

variable "gcp_instance_auto_provision" {
  description = "gcp_instance_auto_provision"
  default     = false
  type        = bool
}

variable "gcp_instance_private_nodes" {
  description = "gcp_instance_private_nodes"
  default     = false
  type        = bool
}

variable "gcp_instance_private_api" {
  description = "gcp_instance_private_api"
  default     = false
  type        = bool
}

variable "gcp_instance_http_balancing" {
  description = "gcp_instance_http_balancing"
  default     = false
  type        = bool
}

variable "gcp_instance_config_connect" {
  description = "gcp_instance_config_connect"
  default     = false
  type        = bool
}

variable "gcp_instance_api_access" {
  description = "gcp_instance_api_access"
  default     = []
  type        = list(string)
}

variable "gcp_instance_security_group" {
  description = "gcp_instance_security_group"
  default     = "gke-security-groups@domain.ca"
  type        = string
}

variable "gcp_instance_accounts" {
  description = "gcp_instance_accounts"
  default     = {}
  type        = map(object({
    projects          = list(string)
    project_roles     = list(string)
    kube_svc_accounts = list(string)
  }))
}
