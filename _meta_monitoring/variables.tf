variable "region" {
  description = "Region in which the resources are deployed"
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS Account Id where resources are deployed"
  type        = string
  default     = "328268088738"
}

# Environment Variable
variable "environment" {
  description = "Environment Variable used as a prefix"
  type        = string
  default     = "dev"
}
# Business Division
variable "business_divsion" {
  description = "Business Division in the large organization this Infrastructure belongs"
  type        = string
  default     = "SAP"
}

variable "namespace" {
  description = "Namespace in which the resources are deployed"
  type        = string
}

variable "service_account_name" {
  description = "Namespace EKS service account"
  type        = string
}

variable "obsrv_domain_name" {
  description = "Obsrv Domain name"
  type        = string
}

variable "skip_tls_verify" {
  description = "To enable/disable TLS"
  type        = bool
}
