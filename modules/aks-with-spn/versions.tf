terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
      version = ">=1.5.0, < 2.0.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">=2.61.0, < 3.0.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">=2.3.0, < 3.0.0"
    }
    random = {
      source = "hashicorp/random"
      version = ">=3.1.0, < 4.0.0"
    }
    null = {
      source = "hashicorp/null"
      version = ">=3.1.0, < 4.0.0"
    }
    time = {
      source = "hashicorp/time"
      version = ">=0.7.0, < 1.0.0"
    }
  }
  required_version = ">= 1.1.3"
}
