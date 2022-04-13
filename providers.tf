provider "azurerm" {
  features {
    key_vault {
      recover_soft_deleted_key_vaults = true
      purge_soft_delete_on_destroy    = true
    }
  }
}

provider "azurerm" {
  alias           = "dmz"
  subscription_id = var.dmz_subscription_id
  features {}
}
