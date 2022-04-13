resource "azuread_application" "cert_manager" {
  display_name = "${var.name}-cert-manager-spn"
  oauth2_allow_implicit_flow = false
}

resource "azuread_service_principal" "cert_manager" {
  application_id = azuread_application.cert_manager.application_id
  app_role_assignment_required = false
}

resource "random_password" "cert_manager" {
  length  = 16
  special = false

  keepers = {
    service_principal = azuread_service_principal.cert_manager.id
  }
}

resource "azuread_service_principal_password" "cert_manager" {
  service_principal_id = azuread_service_principal.cert_manager.id
  value                = random_password.cert_manager.result
  end_date_relative    = "8760h"
}

resource "azuread_application_password" "cert_manager" {
  application_object_id = azuread_application.cert_manager.object_id
  value                 = random_password.cert_manager.result
  end_date_relative     = "8760h"
}

# -- grant reader to aks spn on dns zone resource group
resource "azurerm_role_assignment" "cert_manager_dns_zone_resource_group_reader" {
  scope                = var.dns_zone.resource_group_id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.cert_manager.id
}

# -- grant network contributor to aks spn on dns zone resource
resource "azurerm_role_assignment" "cert_manager_dns_zone_contributor" {
  scope                = var.dns_zone.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azuread_service_principal.cert_manager.id
}

output "cert_manager_spn_app_id" {
  value = azuread_application.cert_manager.application_id
}

output "cert_manager_spn_object_id" {
  value = azuread_service_principal.cert_manager.object_id
}

output "cert_manager_spn_app_secret" {
  value = random_password.cert_manager.result
  sensitive = true
}
