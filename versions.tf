terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">=1.5.0, < 2.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.61.0, < 3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.1.0, < 4.0.0"
    }
  }
  required_version = ">= 1.1.3"
}
