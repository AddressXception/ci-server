provider "azurerm" {
    version = "=1.22.1"
}

terraform {
    backend "azurerm" {}
}