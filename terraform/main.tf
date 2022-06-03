resource "azurerm_resource_group" "infrastructure" {
  name     = "infrastructure"
  location = "westeurope"
}

//--------------------------Container Registry----------------

resource "azurerm_container_registry" "ContainerregistryInfra" {
  name                = "ContainerregistryInfra"
  resource_group_name = azurerm_resource_group.infrastructure.name
  location            = azurerm_resource_group.infrastructure.location
  sku                 = "Standard"
}

//----------Kubernetes Cluster --------------------------------
resource "azurerm_kubernetes_cluster" "infrastructure" {
  name                = "infrastructure-aks1"
  location            = azurerm_resource_group.infrastructure.location
  resource_group_name = azurerm_resource_group.infrastructure.name
  dns_prefix          = "infrastructureaks1"

  default_node_pool {
    name       = "node01"
    node_count = 1
    vm_size    = "Standard_D2as_v5"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}  
//-----------------Key Vault------------------------------------

data "azurerm_client_config" "current" {
}

 resource "azurerm_key_vault" "infrakeyvault123" {
  name                        = "infrakeyvault123"
  location                    = azurerm_resource_group.infrastructure.location
  resource_group_name         = azurerm_resource_group.infrastructure.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name = "standard"
}   


