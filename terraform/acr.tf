resource "azurerm_container_registry" "acr" {
  name                = "acrvoteappivelin"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_role_assignment" "allow_aks_pull_from_acr" {
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name = "AcrPull"

  scope = azurerm_container_registry.acr.id

  skip_service_principal_aad_check = true

  depends_on = [azurerm_kubernetes_cluster.aks]
}