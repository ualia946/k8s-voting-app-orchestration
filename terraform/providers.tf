terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  backend "azurerm" {
    resource_group_name = "rg-tfsate"
    storage_account_name = "accountstoragetfstate"
    container_name = "container-tfstate"
    key = "aks.project.dev.tfstate"
  }
}

provider "azurerm" {
  features {}
}