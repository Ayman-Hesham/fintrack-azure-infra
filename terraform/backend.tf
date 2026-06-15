terraform {
  backend "azurerm" {
    resource_group_name  = "fintrack-tfstate-rg"
    storage_account_name = "stfintracktfstate"
    container_name       = "tfstate"
    key                  = "aks/terraform.tfstate"
  }
}
