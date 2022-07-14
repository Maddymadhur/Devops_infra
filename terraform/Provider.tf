terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.99.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.26.1"
    }
  }
  backend "azurerm" {
    resource_group_name  = "infrastructureaks"
    storage_account_name = "tfstateinfra54321"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }

}

/* provider "azurerm" {
  features {}
}
 */
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

provider "azuread" {
  # Configuration options
}
provider "helm" {
  kubernetes {
    config_path = pathexpand(var.kube_config)
  }
}

provider "kubernetes" {
  config_path = pathexpand(var.kube_config)
}