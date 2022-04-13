variable "aks_nsg_rules" {
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
  default = [

  ]
}

variable "aks_default_pool" {
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
    vm_size             = "Standard_D2ds_v4" # -- must use VM sku with more than 2 cores and 4GB memory
    type                = "VirtualMachineScaleSets"
    availability_zones  = ["1", "2", "3"]
    max_pods            = 30
    node_labels         = {}
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 10
    os_disk_size_gb     = 40
    os_disk_type        = "Ephemeral"
    tags                = {}
  }
}

variable "auto_scaler_profile" {
  type = object({
    balance_similar_node_groups      = bool
    max_graceful_termination_sec     = number
    scale_down_delay_after_add       = string
    scale_down_delay_after_delete    = string
    scale_down_delay_after_failure   = string
    scan_interval                    = string
    scale_down_unneeded              = string
    scale_down_unready               = string
    scale_down_utilization_threshold = number
  })
  default = {
    balance_similar_node_groups      = false # -- detect similar node groups and balance the number of nodes between them - defaults to false
    max_graceful_termination_sec     = 600   # -- maximum number of seconds the cluster autoscaler waits for pod termination when trying to scale down a node - defaults to 600
    scale_down_delay_after_add       = "10m" # -- how long after the scale up of AKS nodes the scale down evaluation resumes - defaults to 10m
    scale_down_delay_after_delete    = "10s" # -- how long after node deletion that scale down evaluation resume - defaults to the value used for scan_interval
    scale_down_delay_after_failure   = "3m"  # -- how long after scale down failure that scale down evaluation resumes - defaults to 3m
    scan_interval                    = "10s" # -- how often the AKS Cluster should be re-evaluated for scale up/down - defaults to 10s
    scale_down_unneeded              = "10m" # -- how long a node should be unneeded before it is eligible for scale down - defaults to 10m
    scale_down_unready               = "20m" # -- how long an unready node should be unneeded before it is eligible for scale down - defaults to 20m
    scale_down_utilization_threshold = 0.5   # -- node utilization level, defined as sum of requested resources divided by capacity, below which a node can be considered for scale down - defaults to 0.5
  }
}

variable "additional_node_pool_subnets" {
  type = list(object({
    name                                          = string
    address_prefixes                              = list(string)
    enforce_private_link_service_network_policies = bool
    nsg = object({
      name = string
      rules = list(object({
        name                         = string
        priority                     = string
        direction                    = string
        access                       = string
        protocol                     = string
        source_port_range            = string
        destination_port_ranges      = list(string)
        source_address_prefix        = string
        source_address_prefixes      = list(string)
        destination_address_prefix   = string
        destination_address_prefixes = list(string)
      }))
    })
  }))
  default = [
  ]
}

variable "aks_api_server_authorized_ip_ranges" {
  type    = list(any)
  default = []
}

variable "aks_additional_linux_node_pools" {
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
  default = [
  ]
}

variable "aks_oms_agent_enabled" {
  type    = bool
  default = true
}

variable "aks_azure_policy_enabled" {
  type    = bool
  default = false
}

variable "aks_kube_dashboard_enabled" {
  type    = bool
  default = true
}

variable "enable_ip_prefix" {
  type    = bool
  default = true
}

data "azurerm_resource_group" "stack_vnet" {
  name = "${local.prefix}-vnet-rg"
}

data "azurerm_virtual_network" "stack_vnet" {
  name                = "${local.prefix}-vnet"
  resource_group_name = "${local.prefix}-vnet-rg"
}

data "azurerm_resource_group" "stack_dns" {
  name = "${local.prefix}-dns-rg"
}

data "azurerm_dns_zone" "stack_dns" {
  name                = local.environment_domain
  resource_group_name = "${local.prefix}-dns-rg"
}

data "azurerm_log_analytics_workspace" "stack_log_analytics" {
  name                = "${local.prefix}-log-analytics"
  resource_group_name = "${local.prefix}-log-analytics-rg"
}

resource "azurerm_role_assignment" "platform_aks_cluster_admin_role_assignments" {
  scope                = module.aks.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = "3845fe50-7c25-4d70-be7f-3cdc3bc29ad2"
}

resource "azurerm_role_assignment" "platform_aks_cluster_admin_cluster_user_role_assignments" {
  scope                = module.aks.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = "3845fe50-7c25-4d70-be7f-3cdc3bc29ad2"
}

locals {
  # -- append prefix, suffix to node pool subnet_name
  flattened_platform_aks_additional_linux_node_pools = flatten([
    for nodepool in var.aks_additional_linux_node_pools : [
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
  # -- append prefix, suffix to subnet name and nsg name
  flattened_platform_additional_node_pool_subnets = flatten([
    for subnet in var.additional_node_pool_subnets : [
      {
        name                                          = "${local.prefix}-${subnet.name}-snet"
        address_prefixes                              = subnet.address_prefixes
        enforce_private_link_service_network_policies = subnet.enforce_private_link_service_network_policies
        nsg = {
          name  = "${local.prefix}-${subnet.nsg.name}-nsg",
          rules = subnet.nsg.rules
        }
      }
    ]
  ])
}

module "aks" {
  source = "./modules/aks-with-spn/"

  name                = "${local.prefix}-aks"
  resource_group_name = "${local.prefix}-aks-rg"
  location            = var.location
  kubernetes_version  = var.kubernetes_version
  virtual_network = {
    name                = data.azurerm_virtual_network.stack_vnet.name
    resource_group_id   = data.azurerm_resource_group.stack_vnet.id
    resource_group_name = data.azurerm_virtual_network.stack_vnet.resource_group_name
  }
  subnet = {
    name             = "${local.prefix}-aks-snet"
    address_prefixes = var.subnets.subnet.aks
  }
  nsg = {
    name  = "${local.prefix}-aks-nsg"
    rules = var.aks_nsg_rules
  }
  aks_api_server_authorized_ip_ranges = var.aks_api_server_authorized_ip_ranges
  default_pool                        = var.aks_default_pool
  auto_scaler_profile                 = var.auto_scaler_profile
  additional_linux_node_pools         = local.flattened_platform_aks_additional_linux_node_pools
  additional_node_pool_subnets        = local.flattened_platform_additional_node_pool_subnets
  azure_policy_enabled                = var.aks_azure_policy_enabled
  oms_agent_enabled                   = var.aks_oms_agent_enabled
  kube_dashboard_enabled              = var.aks_kube_dashboard_enabled
  enable_ip_prefix                    = var.enable_ip_prefix
  log_analytics_workspace_id          = data.azurerm_log_analytics_workspace.stack_log_analytics.id
  dns_zone = {
    id                = data.azurerm_dns_zone.stack_dns.id
    resource_group_id = data.azurerm_resource_group.stack_dns.id
  }
  acr_resource_id = data.azurerm_container_registry.acr.id
  acr_name        = data.azurerm_container_registry.acr.name
  admin_group_ids = ["3845fe50-7c25-4d70-be7f-3cdc3bc29ad2"]

  tags = {}
}
