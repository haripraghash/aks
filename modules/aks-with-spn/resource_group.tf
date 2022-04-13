resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  timeouts {
    create = var.terraform_timeouts.create
    delete = var.terraform_timeouts.delete
    update = var.terraform_timeouts.update
    read   = var.terraform_timeouts.read
  }
  
  tags     = var.tags
}

output "resource_group_id" {
  value = azurerm_resource_group.rg.id
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}
