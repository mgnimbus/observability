variable "aws_region" {
  description = "Region in which AWS Resources to be created"
  type        = string
  default     = "ap-south-2"
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
  default     = "default"
}

variable "service_account_name" {
  description = "Namespace EKS service account"
  type        = string
  default     = "irsa"
}

# Domain Name Service
variable "dns_namespace" {
  description = "Namespace in which the resources are deployed"
  type        = string
  default     = "default"
}

variable "dns_service_account_name" {
  description = "Namespace EKS service account"
  type        = string
}
