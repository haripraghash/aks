data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

data "azurerm_container_registry" "acr" {
  provider = azurerm.dmz

  name                = "${replace(var.dmz_prefix, "-", "")}acr"
  resource_group_name = "${var.dmz_prefix}-acr-rg"
}

data "azurerm_private_dns_zone" "dns" {
  name                = local.environment_domain_private
  resource_group_name = "${local.prefix}-dns-rg"
}
