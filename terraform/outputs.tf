output "acr_name"{
    description = "El nombre del Azure Container Registry creado"
    value = azurerm_container_registry.acr.name
}