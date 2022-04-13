variable "piper_aks_nsg_rules" {
  type = list(object({
    name                         = string
    priority                     = string
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = string
    destination_port_range       = string
    destination_port_ranges      = list(string)
    source_address_prefix        = string
    source_address_prefixes      = list(string)
    destination_address_prefix   = string
    destination_address_prefixes = list(string)
  }))
  default = []
}

variable "piper_aks_default_pool" {
  type = object({
    name                = string
    node_count          = number
    vm_size             = string
    type                = string
    availability_zones  = list(string)
    max_pods            = number
    node_labels         = map(string)
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    os_disk_size_gb     = number
    os_disk_type        = string
    tags                = map(string)
  })
  default = {
    name                = "default"
    node_count          = null
    vm_size             = "Standard_D2ds_v4" # -- must use VM sku with more than 2 cores and 4GB
    type                = "VirtualMachineScaleSets"
    availability_zones  = [ "1", "2", "3" ]
    max_pods            = 30
    node_labels         = {}
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 10
    os_disk_size_gb     = 40
    os_disk_type        = "Ephemeral"
    tags = {}
  }
}

variable "piper_aks_additional_linux_node_pools" {
  type = list(object({
    name                = string
    node_count          = number
    vm_size             = string
    type                = string
    availability_zones  = list(string)
    max_pods            = number
    node_labels         = map(string)
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    node_taints         = list(string)
    os_disk_size_gb     = number
    os_disk_type        = string
    tags                = map(string)
    subnet_name         = string
  }))
  default = []
}

variable "piper_enable_ip_prefix" {
  type    = bool
  default = true
}


data "azurerm_resource_group" "stack_piper_dns" {
  name = "${local.prefix}-dns-piper-rg"
}

data "azurerm_private_dns_zone" "stack_piper_dns" {
  name                = local.environment_domain_piper_private
  resource_group_name = "${local.prefix}-dns-piper-rg"
}



resource "azurerm_role_assignment" "piper_aks_cluster_admin_role_assignments" {
  scope                = module.piper_aks.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = "3845fe50-7c25-4d70-be7f-3cdc3bc29ad2"
}

resource "azurerm_role_assignment" "piper_aks_cluster_admin_cluster_user_role_assignments" {
  scope                = module.piper_aks.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = "3845fe50-7c25-4d70-be7f-3cdc3bc29ad2"
}

locals {
    # -- append prefix, suffix to node pool subnet_name
  flattened_piper_aks_additional_linux_node_pools = flatten([
    for nodepool in var.piper_aks_additional_linux_node_pools : [
      {
        name                = nodepool.name
        node_count          = nodepool.node_count
        vm_size             = nodepool.vm_size
        type                = nodepool.type
        availability_zones  = nodepool.availability_zones
        max_pods            = nodepool.max_pods
        node_labels         = nodepool.node_labels
        enable_auto_scaling = nodepool.enable_auto_scaling
        min_count           = nodepool.min_count
        max_count           = nodepool.max_count
        node_taints         = nodepool.node_taints
        os_disk_size_gb     = nodepool.os_disk_size_gb
        os_disk_type        = nodepool.os_disk_type
        tags                = nodepool.tags
        subnet_name         = "${local.prefix}-${nodepool.subnet_name}-snet"
      }
    ]
  ])
}

module "piper_aks" {
  source = "./modules/aks-with-spn/"

  name                = "${local.prefix}-piper-aks"
  resource_group_name = "${local.prefix}-piper-aks-rg"
  location            = var.location
  kubernetes_version  = var.kubernetes_version
  virtual_network = {
    name                = data.azurerm_virtual_network.stack_vnet.name
    resource_group_id   = data.azurerm_resource_group.stack_vnet.id
    resource_group_name = data.azurerm_virtual_network.stack_vnet.resource_group_name
  }
  subnet = {
    name             = "${local.prefix}-piper-aks-snet"
    address_prefixes = var.subnets.subnet.piper_aks
  }
  nsg = {
    name  = "${local.prefix}-piper-aks-nsg"
    rules = var.piper_aks_nsg_rules
  }
  aks_api_server_authorized_ip_ranges = var.aks_api_server_authorized_ip_ranges
  default_pool                = var.piper_aks_default_pool
  auto_scaler_profile         = var.auto_scaler_profile
  additional_linux_node_pools = local.flattened_piper_aks_additional_linux_node_pools
  azure_policy_enabled        = var.aks_azure_policy_enabled
  oms_agent_enabled           = var.aks_oms_agent_enabled
  kube_dashboard_enabled      = var.aks_kube_dashboard_enabled
  log_analytics_workspace_id  = data.azurerm_log_analytics_workspace.stack_log_analytics.id
  enable_ip_prefix            = var.piper_enable_ip_prefix
  dns_zone = {
    id                = data.azurerm_private_dns_zone.stack_piper_dns.id
    resource_group_id = data.azurerm_resource_group.stack_piper_dns.id
  }
  is_piper = true
  acr_resource_id = data.azurerm_container_registry.acr.id
  admin_group_ids = [ "3845fe50-7c25-4d70-be7f-3cdc3bc29ad2" ]  # -- defined in aks.tf
  acr_name = data.azurerm_container_registry.acr.name
  tags = {}
}
