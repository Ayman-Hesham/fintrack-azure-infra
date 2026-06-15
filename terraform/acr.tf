# ─── Azure Container Registry ────────────────────────────────
resource "azurerm_container_registry" "main" {
  name                = "${var.project_name}acr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false

  # Retention policy for untagged manifests (keep last 5 days)
  # Note: Basic SKU doesn't support retention_policy; images are
  # managed via CI/CD tagging strategy. Upgrade to Standard for
  # retention_policy support if needed.
}

# ─── AKS → ACR Pull Permission ──────────────────────────────
# Grants the AKS kubelet identity permission to pull images
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}
