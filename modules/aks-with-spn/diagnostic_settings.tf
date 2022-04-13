resource "azurerm_monitor_diagnostic_setting" "aks-logging" {
  count               = var.log_analytics_diagnostic_logs_enabled ? 1 : 0

  name                           = "diagnostic_aksl"
  target_resource_id             = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id     = var.log_analytics_workspace_id

  log {
    category = "kube-scheduler"
    enabled  = var.log_analytics_kube_scheduler

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "kube-controller-manager"
    enabled  = var.log_analytics_kube_controller_manager

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "cluster-autoscaler"
    enabled  = var.log_analytics_kube_cluster_autoscaler

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "kube-audit"
    enabled  = var.log_analytics_kube_audit

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "kube-apiserver"
    enabled  = var.log_analytics_kube_apiserver

    retention_policy {
      enabled = false
    }
  }
}
