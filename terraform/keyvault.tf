# ─── Random ID for Key Vault uniqueness ──────────────────────
resource "random_id" "kv_name" {
  byte_length = 4
}

# ─── Azure Key Vault ─────────────────────────────────────────
resource "azurerm_key_vault" "main" {
  name                       = "${var.project_name}-kv-${random_id.kv_name.hex}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

# ─── Terraform deployer needs Key Vault Admin to create secrets
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ─── Database Credential Secrets ─────────────────────────────
resource "azurerm_key_vault_secret" "db_username" {
  name         = "db-credentials-username"
  value        = azurerm_postgresql_flexible_server.main.administrator_login
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-credentials-password"
  value        = random_password.db_password.result
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "db_host" {
  name         = "db-credentials-host"
  value        = azurerm_postgresql_flexible_server.main.fqdn
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "db_port" {
  name         = "db-credentials-port"
  value        = "5432"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "db_database" {
  name         = "db-credentials-database"
  value        = azurerm_postgresql_flexible_server_database.main.name
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "db_url" {
  name         = "db-credentials-url"
  value        = "postgresql://${azurerm_postgresql_flexible_server.main.administrator_login}:${random_password.db_password.result}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.main.name}"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_admin]
}

# ─── Application Secrets ─────────────────────────────────────
resource "random_string" "jwt_secret" {
  length  = 64
  special = false
}

resource "azurerm_key_vault_secret" "jwt_secret" {
  name         = "app-secrets-jwt-secret"
  value        = random_string.jwt_secret.result
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "api_key" {
  name         = "app-secrets-api-key"
  value        = "change-me-in-portal"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "cors_allowed_origins" {
  name         = "app-secrets-cors-allowed-origins"
  value        = "*"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_admin]
}
