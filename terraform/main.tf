//----------------------------------Resource Group------------------------------------------------------------------
resource "azurerm_resource_group" "infrastructureaks" {
  name     = "infrastructureaks"
  location = "westeurope"
}
//---------------------------------Container Registry---------------------------------------------------------------
data "azurerm_client_config" "current" {

}
resource "azurerm_container_registry" "mycontainerregistryinfra" {
  name                = "mycontainerregistryinfra"
  resource_group_name = azurerm_resource_group.infrastructureaks.name
  location            = azurerm_resource_group.infrastructureaks.location
  sku                 = "Standard"
}

//---------------------------------Kubernetes Cluster----------------------------------------------------------------
resource "azurerm_kubernetes_cluster" "infrastructure-aks1" {
  name                = "infrastructure-aks1"
  location            = azurerm_resource_group.infrastructureaks.location
  resource_group_name = azurerm_resource_group.infrastructureaks.name
  dns_prefix          = "infrastructureaks1"

  default_node_pool {
    name       = "node01"
    node_count = 2
    vm_size    = "Standard_D2as_v5"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Dev"
  }
}
//---------------------------------------------Role assignment for container registry------------------------------------------------------------
resource "azurerm_role_assignment" "example" {
  principal_id                     = azurerm_kubernetes_cluster.infrastructure-aks1.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.mycontainerregistryinfra.id
  skip_service_principal_aad_check = true
}
//-----------------------------------------------Key Vault------------------------------------------------------------

resource "azurerm_key_vault" "keyvaultinfra12345" {
  name                        = "keyvaultinfra12345"
  location                    = azurerm_resource_group.infrastructureaks.location
  resource_group_name         = azurerm_resource_group.infrastructureaks.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "00ef2014-e390-44a8-a9c9-d6294d9bc48b"

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }
}
#---------------------------------storage account and storage container for storing the state file -------------------------------

resource "azurerm_storage_account" "tfstate" {
  name                     = "tfstateinfra54321"
  resource_group_name      = azurerm_resource_group.infrastructureaks.name
  location                 = azurerm_resource_group.infrastructureaks.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = true

  tags = {
    environment = "dev"
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "blob"
}


//----------------------------------------------namespaces--------------------------------------------------------------------------

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_namespace" "argo-cd" {
  metadata {
    name = "argo-cd"
  }
}
resource "kubernetes_namespace" "akv2k8s" {
  metadata {
    name = "akv2k8s"
  }
}

resource "kubernetes_namespace" "reloader" {
  metadata {
    name = "reloader"
  }
}

resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "prometheus"
  }
}

resource "kubernetes_namespace" "ingress" {
  metadata {
    name = "ingress"
  }
}
//----------------------------------------------helm chart deployment on AKS--------------------------------------------------------------------------
resource "helm_release" "argo_cd" {
  chart     = "../helm_charts/argo-cd"
  name      = "argo-cd"
  namespace = "argo-cd"
  values = [
    "${file("../helm_charts/argo-cd/myvalues/myvalues.yaml")}"
  ]
}
resource "helm_release" "akv2k8s" {
  chart     = "../helm_charts/akv2k8s"
  name      = "akv2k8s"
  namespace = "akv2k8s"
}

resource "helm_release" "reloader" {
  chart     = "../helm_charts/reloader"
  name      = "reloader"
  namespace = "reloader"
}

resource "helm_release" "prometheus" {
  chart     = "../helm_charts/prometheus"
  name      = "prometheus"
  namespace = "prometheus"
}

resource "helm_release" "ingress-nginx" {
  chart     = "../helm_charts/ingress-nginx"
  name      = "ingress-nginx"
  namespace = "ingress"
}
#-------------------------------------------------------------------------------------------------------------------------------

