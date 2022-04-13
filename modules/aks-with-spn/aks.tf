# -- aks service principal
resource "azuread_application" "aks" {
  display_name               = "${var.name}-spn"
  oauth2_allow_implicit_flow = false
}

resource "azuread_service_principal" "aks" {
  application_id               = azuread_application.aks.application_id
  app_role_assignment_required = false
}

resource "random_password" "aks" {
  length  = 16
  special = true

  keepers = {
    service_principal = azuread_service_principal.aks.id
  }
}

resource "azuread_service_principal_password" "aks" {
  service_principal_id = azuread_service_principal.aks.id
  value                = random_password.aks.result
  end_date_relative    = "8760h"
}

resource "azuread_application_password" "aks" {
  application_object_id = azuread_application.aks.object_id
  value                 = random_password.aks.result
  end_date_relative     = "8760h"
}

resource "time_sleep" "sp_resource_propagation" {
  create_duration = "60s"

  triggers = {
    client_id      = azuread_service_principal.aks.application_id
    client_secret  = azuread_service_principal_password.aks.value
  }
}

// resource "time_sleep" "identity_resource_propagation" {
//   create_duration = "60s"

//   triggers = {
//     client_id      = azurerm_user_assigned_identity.aks_identity.principal_id
//   }
// }

// resource "azurerm_user_assigned_identity" "aks_identity" {
//   resource_group_name = azurerm_resource_group.rg.name
//   location            = azurerm_resource_group.rg.location

//   name = "${var.name}-identity"
// }

# -- grant AKS permission to pull containers from registry
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = var.acr_resource_id
  role_definition_name = "AcrPull"
  //principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id 
  //azurerm_user_assigned_identity.aks_identity.principal_id
  principal_id         = azuread_service_principal.aks.id

  depends_on = [azurerm_kubernetes_cluster.aks]
}

// resource "null_resource" "assign_roles_to_acr_aksidentity"{
//   triggers = {
//     //always_run = "${timestamp()}"
//     aks_identity = azurerm_kubernetes_cluster.aks.identity[0].type
//   }

//   provisioner "local-exec" {
//     command = "${path.module}/assignrolestoidentity.sh ${azurerm_kubernetes_cluster.aks.name} ${azurerm_resource_group.rg.name} ${var.acr_name}"
//   }

//   depends_on =[ azurerm_kubernetes_cluster.aks, time_sleep.identity_resource_propagation ]
// }

locals {
  # -- as an example, taks pol-tune-aks and creates "Pol Tune"
  group_prefix = title(join(" ", slice(split("-", var.name), 0, 2)))
}

# -- aks 
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.name
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.aks_sku_tier
  api_server_authorized_ip_ranges = var.aks_api_server_authorized_ip_ranges

  # -- required from version 2.0
  default_node_pool {
    name       = var.default_pool.name
    node_count = var.default_pool.node_count
    vm_size    = var.default_pool.vm_size
    orchestrator_version = var.kubernetes_version
    # -- if VirtualMachineScaleSets, requires load_balancer_sku of Standard
    type = var.default_pool.type

    availability_zones = var.default_pool.availability_zones
    max_pods           = var.default_pool.max_pods

    # -- defaults to false
    enable_auto_scaling = var.default_pool.enable_auto_scaling

    min_count       = var.default_pool.min_count
    max_count       = var.default_pool.max_count
    os_disk_size_gb = var.default_pool.os_disk_size_gb
    os_disk_type    = var.default_pool.os_disk_type

    # -- requires route table configured on subnet
    vnet_subnet_id = azurerm_subnet.aks_subnet.id

    tags = var.default_pool.tags
  }

  addon_profile {
    oms_agent {
      enabled                    = var.oms_agent_enabled
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }

    aci_connector_linux {
      enabled = var.aci_connector_linux_enabled
    }

    azure_policy {
      enabled = var.azure_policy_enabled
    }

    http_application_routing {
      enabled = var.http_application_routing_enabled
    }
    
    kube_dashboard {
      enabled = false
    }
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    docker_bridge_cidr = var.network_profile.docker_bridge_cidr
    dns_service_ip     = var.network_profile.dns_service_ip
    service_cidr       = var.network_profile.service_cidr

    # -- nginx is complaining the ip is in use, have commented this out but still creating the static public ip - use nginx_pip
    load_balancer_sku = "standard"
    load_balancer_profile {
      outbound_ip_address_ids = [
        azurerm_public_ip.pip.id
      ]
    }
  }

  // identity {
  //     type = "UserAssigned"
  //     user_assigned_identity_id = azurerm_user_assigned_identity.aks_identity.id
  // }
  service_principal {
    client_id     = time_sleep.sp_resource_propagation.triggers["client_id"]
    client_secret = time_sleep.sp_resource_propagation.triggers["client_secret"]
  }

  role_based_access_control {
    enabled = true

    azure_active_directory {
      managed = true
      admin_group_object_ids = var.admin_group_ids
    }
  }

  timeouts {
    create = var.terraform_timeouts.create
    delete = var.terraform_timeouts.delete
    update = var.terraform_timeouts.update
    read   = var.terraform_timeouts.read
  }

  tags = var.tags

  depends_on = [
    azurerm_public_ip.pip
  ]

  lifecycle {
    ignore_changes = [
      default_node_pool.0.node_count
    ]
  }
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = var.virtual_network.resource_group_id
  role_definition_name = "Network Contributor"
  //principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  principal_id         = azuread_service_principal.aks.object_id
}

resource "azurerm_role_assignment" "aks_monitoring" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Monitoring Metrics Publisher"
  //principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  principal_id         = azuread_service_principal.aks.object_id
}

output "aks_application_id" {
  //value =  azurerm_user_assigned_identity.aks_identity.principal_id
  value = azuread_application.aks.application_id
}

// output "aks_kubelet_application_id" {
//   value = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
// }

// output "aks_omsagent_application_id" {
//   value = azurerm_kubernetes_cluster.aks.addon_profile[0].oms_agent[0].oms_agent_identity[0].object_id
// }

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config
}

output "kube_admin_config" {
  value = azurerm_kubernetes_cluster.aks.kube_admin_config
}

output "id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "host" {
  value = azurerm_kubernetes_cluster.aks.kube_config[0].host
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate
  sensitive = true
}

output "node_resource_group" {
  value = azurerm_kubernetes_cluster.aks.node_resource_group
}
