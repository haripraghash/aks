resource "azurerm_kubernetes_cluster_node_pool" "linux_node_pools" {
  for_each = { for node_pool in var.additional_linux_node_pools : node_pool.name => node_pool }

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count
  availability_zones    = each.value.availability_zones
  max_pods              = each.value.max_pods
  node_labels           = each.value.node_labels
  enable_auto_scaling   = each.value.enable_auto_scaling
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  node_taints           = each.value.node_taints

  # -- TODO: investigate usage of Spot, eviction_policy needs setting when 'Spot' enabled
  priority        = "Regular"
  os_type         = "Linux"
  os_disk_size_gb = each.value.os_disk_size_gb
  os_disk_type    = each.value.os_disk_type

  # -- NOTE: can also be System
  mode                 = "User"
  orchestrator_version = azurerm_kubernetes_cluster.aks.kubernetes_version
  vnet_subnet_id = each.value.subnet_name == azurerm_subnet.aks_subnet.name ? azurerm_subnet.aks_subnet.id : azurerm_subnet.additional_node_pool[each.value.subnet_name].id

  timeouts {
    create = var.terraform_timeouts.create
    delete = var.terraform_timeouts.delete
    update = var.terraform_timeouts.update
    read   = var.terraform_timeouts.read
  }

  tags = merge(var.tags, each.value.tags)
}

output "linux_node_pools" {
  value = tomap({
    for node_pool in azurerm_kubernetes_cluster_node_pool.linux_node_pools : node_pool.name => node_pool.id
  })
}
