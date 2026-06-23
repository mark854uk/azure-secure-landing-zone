variable "subscription_id" {
  description = "Azure subscription ID to deploy into. Find it with: az account show --query id -o tsv"
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "uksouth"
}

variable "prefix" {
  description = "Short lowercase prefix for resource names (3-8 chars, letters/digits only)."
  type        = string
  default     = "seclz"

  validation {
    condition     = can(regex("^[a-z0-9]{3,8}$", var.prefix))
    error_message = "Prefix must be 3-8 lowercase letters or digits (storage account names are strict)."
  }
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default = {
    project     = "azure-secure-landing-zone"
    environment = "demo"
    managed_by  = "terraform"
  }
}
