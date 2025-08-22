resource "azurerm_resource_group" "tfstate" {
  name = "rg-tfstate"
  location = "France Central"
}

resource "azurerm_storage_account" "tfstate" {
  name = "accountstoragetfstate"
  location = azurerm_resource_group.tfstate.location
  resource_group_name = azurerm_resource_group.tfstate.name

  account_tier = "Basic"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfstate" {
  name = "container-tfstate"
  storage_account_id = azurerm_storage_account.tfstate.id
}