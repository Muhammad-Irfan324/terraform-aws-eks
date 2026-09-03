######################################################################
# Required Variables
######################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string

  validation {
    condition     = length(var.cluster_name) >= 1 && length(var.cluster_name) <= 100
    error_message = "cluster_name must be between 1 and 100 characters."
  }
}

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "vpc_id must be a valid VPC ID (e.g. vpc-0abc1234def56789a)."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster and node groups (at least 2 in different AZs)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs in different availability zones are required."
  }
}

######################################################################
# Cluster Configuration
######################################################################

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.35"

  validation {
    condition     = can(regex("^1\\.(2[5-9]|3[0-9])$", var.kubernetes_version))
    error_message = "kubernetes_version must be a supported EKS version (1.25+)."
  }
}

variable "cluster_endpoint_public_access" {
  description = "Whether the Kubernetes API server endpoint is publicly accessible"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Whether the Kubernetes API server endpoint is accessible from within the VPC"
  type        = bool
  default     = true
}

variable "enabled_cluster_log_types" {
  description = "List of EKS control plane log types to enable (api, audit, authenticator, controllerManager, scheduler)"
  type        = list(string)
  default     = ["api", "audit", "authenticator"]

  validation {
    condition = alltrue([
      for t in var.enabled_cluster_log_types : contains(
        ["api", "audit", "authenticator", "controllerManager", "scheduler"], t
      )
    ])
    error_message = "Each log type must be one of: api, audit, authenticator, controllerManager, scheduler."
  }
}

######################################################################
# Node Group Configuration
######################################################################

variable "node_groups" {
  description = <<-EOT
    Map of managed node groups to create. Each key becomes the node group
    name. All fields are optional and fall back to sensible defaults.

    Example:
      node_groups = {
        system   = { instance_types = ["t3.medium"], desired_size = 2 }
        workload = { instance_types = ["t3.large"],  min_size = 2, max_size = 10 }
      }
  EOT
  type = map(object({
    instance_types = optional(list(string), ["t3.medium"])
    ami_type       = optional(string, "AL2023_x86_64_STANDARD")
    disk_size      = optional(number, 50)
    desired_size   = optional(number, 2)
    min_size       = optional(number, 1)
    max_size       = optional(number, 4)
  }))
  default = {
    default = {}
  }
}

######################################################################
# Add-ons
######################################################################

variable "cluster_addons" {
  description = <<-EOT
    Map of EKS add-ons to install. Keys are add-on names, values are
    objects with an optional version override. When version is null the
    latest compatible version is installed automatically.

    Common add-ons: vpc-cni, coredns, kube-proxy, aws-ebs-csi-driver.
  EOT
  type = map(object({
    version = optional(string, null)
  }))
  default = {
    vpc-cni            = {}
    coredns            = {}
    kube-proxy         = {}
    aws-ebs-csi-driver = {}
  }
}

######################################################################
# Optional Variables
######################################################################

variable "cluster_encryption_key_arn" {
  description = "ARN of the KMS key to encrypt Kubernetes secrets at rest. When null, secrets encryption is disabled."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources created by this module"
  type        = map(string)
  default     = {}
}
