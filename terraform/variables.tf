variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "azure_location" {
  description = "Azure region (Poland Central - cheapest in Europe)"
  type        = string
  default     = "polandcentral"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "fintrack"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "learning"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.34"
}

variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_prefix" {
  description = "AKS subnet address prefix"
  type        = string
  default     = "10.0.1.0/24"
}

variable "appgw_subnet_prefix" {
  description = "Application Gateway subnet address prefix"
  type        = string
  default     = "10.0.2.0/24"
}

variable "postgresql_subnet_prefix" {
  description = "PostgreSQL delegated subnet address prefix"
  type        = string
  default     = "10.0.3.0/24"
}

variable "node_vm_size" {
  description = "VM size for AKS nodes (Standard_D2s_v4 = 2 vCPU, 8 GiB, general purpose)"
  type        = string
  default     = "Standard_D2s_v4"
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "node_desired_size" {
  description = "Initial number of worker nodes"
  type        = number
  default     = 2
}

variable "pg_sku_name" {
  description = "PostgreSQL Flexible Server SKU (B_Standard_B1ms = Burstable, 1 vCPU, 2 GiB)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "pg_storage_mb" {
  description = "PostgreSQL storage size in MB (32768 = 32 GB, Azure minimum)"
  type        = number
  default     = 32768
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "Ayman-Hesham"
}

variable "github_repo" {
  description = "GitHub repository name for application code"
  type        = string
  default     = "Fintrack"
}

variable "alertmanager_smtp_password" {
  description = "Gmail App Password for Alertmanager SMTP"
  type        = string
  sensitive   = true
}
