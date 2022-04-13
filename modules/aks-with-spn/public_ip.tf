resource "azurerm_public_ip" "pip" {
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  domain_name_label   = var.name
  sku                 = "Standard"
  public_ip_prefix_id = var.enable_ip_prefix == true ? azurerm_public_ip_prefix.pip_prefix[0].id : null
}

resource "azurerm_public_ip" "nginx_pip" {
  name                = "${var.name}-nginx-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  domain_name_label   = "${var.name}-nginx"
  sku                 = "Standard"
  public_ip_prefix_id = var.enable_ip_prefix == true ? azurerm_public_ip_prefix.pip_prefix[0].id : null

  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

# -- provides a fixed range from which the public ip addresses for aks are always taken
resource "azurerm_public_ip_prefix" "pip_prefix" {
  count               = var.enable_ip_prefix ? 1 : 0

  name                = "${var.name}-pip-prefix"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  prefix_length       = var.ip_prefix_length
}

data  "azurerm_resource_group" "node_resgrp" {
  name = azurerm_kubernetes_cluster.aks.node_resource_group
}

# -- required as public ip is stored in different resource group to the aks managed resource group
# -- nginx/istio assumes public ip is in the managed resource group but can get around this with role assignment
resource "azurerm_role_assignment" "aks_contributor_pip_rg" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Network Contributor"
  //principal_id         =  azurerm_user_assigned_identity.aks_identity.principal_id
  principal_id = azuread_application.aks.application_id
}

resource "azurerm_role_assignment" "aks_contributor_vnet_rg" {
  scope                = var.virtual_network.resource_group_id
  role_definition_name = "Network Contributor"
  //principal_id         =  azurerm_user_assigned_identity.aks_identity.principal_id
  principal_id = azuread_application.aks.application_id
  skip_service_principal_aad_check = true
}

// resource "azurerm_role_assignment" "aks_contributor_pip_node_rg" {
//   scope                = data.azurerm_resource_group.node_resgrp.id
//   role_definition_name = "Network Contributor"
//   //principal_id         =  azurerm_user_assigned_identity.aks_identity.principal_id
//   principal_id = azuread_application.aks.application_id
// }

output "public_ip_id" {
  value = azurerm_public_ip.pip.id
}

output "public_ip_address" {
  value = azurerm_public_ip.pip.ip_address
}

output "public_ip_fqdn" {
  value = azurerm_public_ip.pip.fqdn
}

output "nginx_public_ip_id" {
  value = azurerm_public_ip.nginx_pip.id
}

output "nginx_public_ip_address" {
  value = azurerm_public_ip.nginx_pip.ip_address
}

output "nginx_public_ip_fqdn" {
  value = azurerm_public_ip.nginx_pip.fqdn
}

output "public_ip_prefix" {
  value = azurerm_public_ip_prefix.pip_prefix.*.ip_prefix
}
