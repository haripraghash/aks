resource "azurerm_subnet" "aks_subnet" {
  name                 = var.subnet.name
  resource_group_name  = var.virtual_network.resource_group_name
  address_prefixes     = var.subnet.address_prefixes
  virtual_network_name = var.virtual_network.name
  service_endpoints = [
    "Microsoft.AzureCosmosDB",
    "Microsoft.KeyVault",
    "Microsoft.Sql",
    "Microsoft.Storage",
  ]
}

resource "azurerm_network_security_group" "aks_nsg" {
  name                = var.nsg.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "aks_nsg" {
  for_each = { for rules in var.nsg.rules : rules.name => rules }

  resource_group_name          = azurerm_resource_group.rg.name
  network_security_group_name  = azurerm_network_security_group.aks_nsg.name
  name                         = each.value.name
  priority                     = each.value.priority
  direction                    = each.value.direction
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_range            = each.value.source_port_range
  destination_port_range       = each.value.destination_port_range != "" ? each.value.destination_port_range : null
  destination_port_ranges      = length(each.value.destination_port_ranges) > 0 ? each.value.destination_port_ranges : null
  source_address_prefix        = each.value.source_address_prefix != "" ? each.value.source_address_prefix : null
  source_address_prefixes      = length(each.value.source_address_prefixes) > 0 ? each.value.source_address_prefixes : null
  destination_address_prefix   = each.value.destination_address_prefix != "" ? each.value.destination_address_prefix : null
  destination_address_prefixes = length(each.value.destination_address_prefixes) > 0 ? each.value.destination_address_prefixes : null
}

resource "azurerm_subnet_network_security_group_association" "aks_nsg" {
  subnet_id                 = azurerm_subnet.aks_subnet.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id

  lifecycle {
    ignore_changes = [
      subnet_id,
      network_security_group_id
    ]
  }
}

# -- additional subnets for additional node pools
locals {
  flat_additional_node_pool_nsgs = flatten([
    for subnet in var.additional_node_pool_subnets : [
      for rules in subnet.nsg.rules :
      {
        nsg_name                     = subnet.nsg.name
        name                         = rules.name
        priority                     = rules.priority
        direction                    = rules.direction
        access                       = rules.access
        protocol                     = rules.protocol
        source_port_range            = rules.source_port_range
        destination_port_ranges      = rules.destination_port_ranges
        source_address_prefix        = rules.source_address_prefix
        source_address_prefixes      = rules.source_address_prefixes
        destination_address_prefix   = rules.destination_address_prefix
        destination_address_prefixes = rules.destination_address_prefixes
      }
    ]
  ])
}

resource "azurerm_subnet" "additional_node_pool" {
  for_each             = { for subnet in var.additional_node_pool_subnets : subnet.name => subnet }
  name                 = each.key
  resource_group_name  = var.virtual_network.resource_group_name
  address_prefixes     = each.value.address_prefixes
  virtual_network_name = var.virtual_network.name
  service_endpoints = [
    "Microsoft.AzureCosmosDB",
    "Microsoft.KeyVault",
    "Microsoft.Sql",
    "Microsoft.Storage",
  ]
  enforce_private_link_service_network_policies = each.value.enforce_private_link_service_network_policies
}

resource "azurerm_network_security_group" "additional_node_pool" {
  for_each            = { for subnet in var.additional_node_pool_subnets : subnet.nsg.name => subnet.nsg }
  name                = each.value.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "additional_node_pool_nsg" {
  for_each = { for rules in local.flat_additional_node_pool_nsgs : "${rules.nsg_name}.${rules.name}" => rules }

  resource_group_name          = azurerm_resource_group.rg.name
  network_security_group_name  = azurerm_network_security_group.additional_node_pool[each.value.nsg_name].name
  name                         = each.value.name
  priority                     = each.value.priority
  direction                    = each.value.direction
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_range            = each.value.source_port_range
  destination_port_ranges      = each.value.destination_port_ranges
  source_address_prefix        = each.value.source_address_prefix != "" ? each.value.source_address_prefix : null
  source_address_prefixes      = length(each.value.source_address_prefixes) > 0 ? each.value.source_address_prefixes : null
  destination_address_prefix   = each.value.destination_address_prefix != "" ? each.value.destination_address_prefix : null
  destination_address_prefixes = length(each.value.destination_address_prefixes) > 0 ? each.value.destination_address_prefixes : null
}

resource "azurerm_subnet_network_security_group_association" "additional_node_pool_nsg" {
  for_each                  = { for subnet in var.additional_node_pool_subnets : subnet.name => subnet }
  subnet_id                 = azurerm_subnet.additional_node_pool[each.key].id
  network_security_group_id = azurerm_network_security_group.additional_node_pool[each.value.nsg.name].id

  lifecycle {
    ignore_changes = [
      subnet_id,
      network_security_group_id
    ]
  }
}

output "subnet_id" {
  value = azurerm_subnet.aks_subnet.id
}

output "subnet_name" {
  value = azurerm_subnet.aks_subnet.name
}

output "subnet_address_prefixes" {
  value = azurerm_subnet.aks_subnet.address_prefixes
}
