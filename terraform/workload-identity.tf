# ═══════════════════════════════════════════════════════════════
# Workload Identity — replaces all 4 AWS IRSA files
# Uses Azure AD Managed Identities + Federated Credentials
# to grant pods access to Azure resources via OIDC tokens.
# ═══════════════════════════════════════════════════════════════

# ─── External Secrets Operator Identity ──────────────────────
resource "azurerm_user_assigned_identity" "external_secrets" {
  name                = "${var.project_name}-external-secrets"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_federated_identity_credential" "external_secrets" {
  name                      = "${var.project_name}-external-secrets"
  user_assigned_identity_id = azurerm_user_assigned_identity.external_secrets.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject                   = "system:serviceaccount:application:external-secrets"
}

# ESO needs to read secrets from Key Vault
resource "azurerm_role_assignment" "external_secrets_kv" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.external_secrets.principal_id
}

# ─── Loki Identity ──────────────────────────────────────────
resource "azurerm_user_assigned_identity" "loki" {
  name                = "${var.project_name}-loki"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_federated_identity_credential" "loki" {
  name                      = "${var.project_name}-loki"
  user_assigned_identity_id = azurerm_user_assigned_identity.loki.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject                   = "system:serviceaccount:observability:loki"
}

# Loki needs to read/write blobs in the storage account
resource "azurerm_role_assignment" "loki_storage" {
  scope                = azurerm_storage_account.loki.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.loki.principal_id
}
