# ─── Private DNS Zone for PostgreSQL ─────────────────────────
resource "azurerm_private_dns_zone" "postgresql" {
  name                = "${var.project_name}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = "${var.project_name}-pg-vnet-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

# ─── Random Password (same pattern as AWS) ──────────────────
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# ─── PostgreSQL Flexible Server (VNet-integrated, private) ──
resource "azurerm_postgresql_flexible_server" "main" {
  name                          = "${var.project_name}-db"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  version                       = "17"
  delegated_subnet_id           = azurerm_subnet.postgresql.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgresql.id
  public_network_access_enabled = false

  administrator_login    = "fintrackadmin"
  administrator_password = random_password.db_password.result

  sku_name   = var.pg_sku_name
  storage_mb = var.pg_storage_mb

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql]

  lifecycle {
    ignore_changes = [
      zone,
      high_availability,
    ]
  }
}

# ─── Application Database ───────────────────────────────────
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "fintrackdb"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
