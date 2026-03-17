terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 4.8.0"
    }
  }
  backend "azurerm" {
    resource_group_name = "tfstate-day04" 
    storage_account_name = "day0432318"                                
    container_name       = "tfstate"                                  
    key                  = "dev.terraform.tfstate"                  
  }
  required_version = ">=1.9.0"
}

provider "azurerm" {
  features {
    
  }
}

variable "environment" {
    type = string
    description = "the env type"
    default = "staging"
}

locals {
  common_tags = {
    environment = "dev"
    lob = "banking"
    stage = "alpha"
  }
}

resource "azurerm_resource_group" "example" {
  name     = "example-storagerg"
  location = "West Europe"
}

resource "azurerm_storage_account" "example" {
  name                     = "azureramstorage"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location #implicit dependency
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = local.common_tags.stage
  }
}

output "storage_account_name" {
    value = azurerm_storage_account.example.name
}