terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  backend "azurerm" {
    resource_group_name = "rg-terraform-state"
    storage_account_name = "terraformstateivelin"
    container_name = "tfstate"
    key = "aks.project.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}