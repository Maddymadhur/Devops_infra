//----------------------------------Resource Group------------------------------------------------------------------
resource "azurerm_resource_group" "infrastructureaks" {
  name     = "infrastructureaks"
  location = "westeurope"
}
//---------------------------------Container Registry---------------------------------------------------------------
data "azurerm_client_config" "current" {

}
resource "azurerm_container_registry" "ContainerregistryInfra" {
  name                = "ContainerregistryInfra"
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
  principal_id                     =  data.azurerm_client_config.current.client_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.ContainerregistryInfra.id
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

//----------------------------------------------namespaces--------------------------------------------------------------------------

/* resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
  }
} */

//--------------------------------------------------prometheus-----------------------------------------------------------------resource "helm_release" "prometheus" {/* 
 /* resource "helm_release" "argocd" {
  chart      = "../argo-cd"
  name       = "argocd"
  namespace  = "argocd"
  verify = false
 }  */
//----------------------------------------------------grafana--------------------------------------------------------------

/* resource "kubernetes_secret" "grafana" {yes

  metadata {
    name      = "grafana"
    namespace = var.namespace
  } 

  data = {
    admin-user     = "admin"
    admin-password = random_password.grafana.result
  }
}

resource "random_password" "grafana" {
  length = 24
}

resource "helm_release" "grafana" {
  chart      = "grafana"
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  namespace  = var.namespace
  version    = "6.24.1"

  values = [
    templatefile("${path.module}/templates/grafana-values.yaml", {
      admin_existing_secret = kubernetes_secret.grafana.metadata[0].name
      admin_user_key        = "admin-user"
      admin_password_key    = "admin-password"
      prometheus_svc        = "${helm_release.prometheus.name}-server"
      replicas              = 1
    })
  ]
}

*/
//------------------------------------------------------------------------------------------------------------------------




