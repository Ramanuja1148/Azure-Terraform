terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 4.8.0"
    }
  }
  required_version = ">=1.9.0"
}

provider "azurerm" {
  features {
    
  }
  subscription_id = "f37ab495-c9c5-4fb9-8136-f653fd181936"
}