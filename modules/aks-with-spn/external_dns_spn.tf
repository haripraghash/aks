resource "azuread_application" "external_dns" {
  name = "${var.name}-external-dns-spn"
  oauth2_allow_implicit_flow = false
}

resource "azuread_service_principal" "external_dns" {
  application_id = azuread_application.external_dns.application_id
  app_role_assignment_required = false
}

resource "random_password" "external_dns" {
  length  = 16
  special = true

  keepers = {
    service_principal = azuread_service_principal.external_dns.id
  }
}

resource "azuread_service_principal_password" "external_dns" {
  service_principal_id = azuread_service_principal.external_dns.id
  value                = random_password.external_dns.result
  end_date_relative    = "8760h"
}

resource "azuread_application_password" "external_dns" {
  application_object_id = azuread_application.external_dns.object_id
  value                 = random_password.external_dns.result
  end_date_relative     = "8760h"
}

# -- grant reader to aks spn on dns zone resource group
resource "azurerm_role_assignment" "external_dns_zone_resource_group_reader" {
  scope                = var.dns_zone.resource_group_id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.external_dns.id
}

# -- grant network contributor to aks spn on dns zone resource
resource "azurerm_role_assignment" "external_dns_zone_contributor" {
  scope                = var.dns_zone.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.external_dns.id
}

# -- grant private dns network contributor to aks spn on private dns zone resource if it's piper
resource "azurerm_role_assignment" "external_private_dns_zone_contributor" {
  count               = var.is_piper ? 1 : 0
  scope                = var.dns_zone.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azuread_service_principal.external_dns.id
}

output "external_dns_spn_app_id" {
  value = azuread_application.external_dns.application_id
}

output "external_dns_spn_object_id" {
  value = azuread_service_principal.external_dns.object_id
}

output "external_dns_spn_app_secret" {
  value = random_password.external_dns.result
  sensitive = true
}