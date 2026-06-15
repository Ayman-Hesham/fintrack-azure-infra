# ─── Storage Account for Loki Logs ───────────────────────────
resource "azurerm_storage_account" "loki" {
  name                     = "${var.project_name}loki"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }
}

# ─── Blob Container for Loki Chunks + Index ──────────────────
resource "azurerm_storage_container" "loki" {
  name                  = "loki-logs"
  storage_account_id    = azurerm_storage_account.loki.id
  container_access_type = "private"
}

# ─── Lifecycle Management (matches S3 policy: 30d cool, 90d delete)
resource "azurerm_storage_management_policy" "loki" {
  storage_account_id = azurerm_storage_account.loki.id

  rule {
    name    = "expire-old-logs"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["loki-logs/"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        delete_after_days_since_modification_greater_than          = 90
      }
    }
  }
}
