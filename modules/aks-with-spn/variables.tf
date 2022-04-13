variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
  default = "northeurope"
}

variable "kubernetes_version" {
  type    = string
  default = "1.21.7"
}

variable "aks_api_server_authorized_ip_ranges" {
  type    = list
  default = []
}

variable "network_profile" {
  type = object({
    docker_bridge_cidr = string
    dns_service_ip     = string
    service_cidr       = string
  })
  default = {
    docker_bridge_cidr = "172.17.0.1/16"
    dns_service_ip     = "10.0.0.10"
    service_cidr       = "10.0.0.0/16"
  }
}

variable "virtual_network" {
  type = object({
    name                = string
    resource_group_id   = string
    resource_group_name = string
  })
}

variable "subnet" {
  type = object({
    name             = string
    address_prefixes = list(string)
  })
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
  default = []
}

variable "nsg" {
  type = object({
    name = string
    rules = list(object({
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
  })
}

variable "default_pool" {
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
}

variable "additional_linux_node_pools" {
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
    # -- detect similar node groups and balance the number of nodes between them - defaults to false
    balance_similar_node_groups = false
    # -- maximum number of seconds the cluster autoscaler waits for pod termination when trying to scale down a node - defaults to 600
    max_graceful_termination_sec = 600
    # -- how long after the scale up of AKS nodes the scale down evaluation resumes - defaults to 10m
    scale_down_delay_after_add = "10m"
    # -- how long after node deletion that scale down evaluation resume - defaults to the value used for scan_interval
    scale_down_delay_after_delete = "10s"
    # -- how long after scale down failure that scale down evaluation resumes - defaults to 3m
    scale_down_delay_after_failure = "3m"
    # -- how often the AKS Cluster should be re-evaluated for scale up/down - defaults to 10s
    scan_interval = "10s"
    # -- how long a node should be unneeded before it is eligible for scale down - defaults to 10m
    scale_down_unneeded = "10m"
    # -- how long an unready node should be unneeded before it is eligible for scale down - defaults to 20m
    scale_down_unready = "20m"
    # -- node utilization level, defined as sum of requested resources divided by capacity, below which a node can be considered for scale down - defaults to 0.5
    scale_down_utilization_threshold = 0.5
  }
}

variable "oms_agent_enabled" {
  type    = bool
  default = false
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "log_analytics_diagnostic_logs_enabled" {
  type    = bool
  default = false
}

variable "log_analytics_kube_scheduler" {
  type    = bool
  default = false
}

variable "log_analytics_kube_controller_manager" {
  type    = bool
  default = false
}

variable "log_analytics_kube_cluster_autoscaler" {
  type    = bool
  default = false
}

variable "log_analytics_kube_audit" {
  type    = bool
  default = false
}

variable "log_analytics_kube_apiserver" {
  type    = bool
  default = false
}

variable "kube_dashboard_enabled" {
  type    = bool
  default = false
}

variable "aci_connector_linux_enabled" {
  type    = bool
  default = false
}

variable "azure_policy_enabled" {
  type    = bool
  default = false
}

variable "http_application_routing_enabled" {
  type    = bool
  default = true
}

variable "rbac" {
  type = object({
    enabled = bool
    managed = bool
  })
  default = {
    enabled = true
    managed = true
  }
}

variable "dns_zone" {
  type = object({
    id                = string
    resource_group_id = string
  })
}

variable "terraform_timeouts" {
  type = object({
    create = string
    delete = string
    update = string
    read   = string
  })
  default = {
    create = "300m"
    delete = "300m"
    update = "300m"
    read   = "30m"
  }
}

variable "tags" {
  type = map(string)
}

variable "acr_resource_id" {
  type = string
}

variable "acr_name" {
  type = string
}

variable "ip_prefix_length" {
  type    = number
  default = 31
}

variable "enable_ip_prefix" {
  type    = bool
  default = true
}

variable "is_piper" {
  type    = bool
  default = false
}

variable "aks_sku_tier" {
  type    = string
  default = "Paid"
}

# -- pass admin group ids instead of creating them in module to allow reuse of AKS Admins groups
# -- across module instances and prevent duplicate groups
variable "admin_group_ids" {
  type = list(string)
}
