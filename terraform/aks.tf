# ─── AKS Cluster ─────────────────────────────────────────────
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.project_name}-aks"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  dns_prefix          = var.project_name
  kubernetes_version  = var.cluster_version

  # System node pool — Standard_B2s burstable VMs (cost-optimized)
  default_node_pool {
    name                        = "system"
    vm_size                     = var.node_vm_size
    node_count                  = var.node_desired_size
    min_count                   = var.node_min_size
    max_count                   = var.node_max_size
    auto_scaling_enabled        = true
    vnet_subnet_id              = azurerm_subnet.aks.id
    os_disk_size_gb             = 30
    temporary_name_for_rotation = "systemtmp"

    node_labels = {
      Environment = var.environment
      Role        = "worker"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  # Workload Identity (replaces AWS IRSA)
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Azure CNI — pods get VNet IPs, required for AGIC routing
  network_profile {
    network_plugin = "azure"
    service_cidr   = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"
  }

  # AGIC addon — replaces AWS ALB Ingress Controller
  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.main.id
  }
}

# ─── AGIC Role Assignments ──────────────────────────────────
# AGIC identity needs Contributor on AppGW to manage routing
resource "azurerm_role_assignment" "agic_appgw" {
  scope                = azurerm_application_gateway.main.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.main.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}

resource "azurerm_role_assignment" "agic_rg_reader" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Reader"
  principal_id         = azurerm_kubernetes_cluster.main.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}

# AKS identity needs Network Contributor on AKS subnet
resource "azurerm_role_assignment" "aks_network" {
  scope                = azurerm_subnet.aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

# AKS identity needs Network Contributor on AppGW subnet
resource "azurerm_role_assignment" "aks_appgw_subnet" {
  scope                = azurerm_subnet.appgw.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
}
