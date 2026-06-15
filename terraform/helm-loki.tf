resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "5.47.1"
  namespace  = kubernetes_namespace.observability.metadata[0].name

  values = [yamlencode({
    deploymentMode = "SingleBinary"

    loki = {
      auth_enabled = false
      storage = {
        type = "azure"
        azure = {
          accountName       = azurerm_storage_account.loki.name
          containerName     = azurerm_storage_container.loki.name
          useFederatedToken = true
        }
      }

      commonConfig = {
        replication_factor = 1
      }
      schemaConfig = {
        configs = [{
          from         = "2026-01-22"
          store        = "tsdb"
          object_store = "azure"
          schema       = "v13"
          index = {
            prefix = "index_"
            period = "24h"
          }
        }]
      }

      storage_config = {
        tsdb_shipper = {
          active_index_directory = "/var/loki/tsdb-index"
          cache_location         = "/var/loki/tsdb-cache"
        }
      }

      limits_config = {
        retention_period            = "30d"
        ingestion_rate_mb           = 4
        ingestion_burst_size_mb     = 6
        max_streams_per_user        = 10000
        max_global_streams_per_user = 10000
      }
    }

    singleBinary = {
      replicas = 1
      persistence = {
        enabled = true
        size    = "2Gi"
      }
    }

    serviceAccount = {
      create = true
      name   = "loki"
      annotations = {
        "azure.workload-identity/client-id" = azurerm_user_assigned_identity.loki.client_id
      }
      labels = {
        "azure.workload-identity/use" = "true"
      }
    }

    backend = {
      replicas = 0
    }
    read = {
      replicas = 0
    }
    write = {
      replicas = 0
    }

    gateway = {
      enabled  = true
      replicas = 1
    }

    minio = {
      enabled = false
    }

    monitoring = {
      selfMonitoring = {
        enabled = false
      }
      lokiCanary = {
        enabled = false
      }
    }

    test = {
      enabled = false
    }
  })]

  depends_on = [
    kubernetes_namespace.observability,
    azurerm_storage_container.loki,
    azurerm_role_assignment.loki_storage
  ]
}

resource "helm_release" "fluent_bit" {
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = "0.43.0"
  namespace  = kubernetes_namespace.observability.metadata[0].name

  values = [yamlencode({
    config = {
      outputs = <<-EOT
        [OUTPUT]
            Name        loki
            Match       kube.*
            Host        loki-gateway.observability.svc.cluster.local
            Port        80
            Labels      job=fluent-bit
            Auto_Kubernetes_Labels on
      EOT
    }
  })]

  depends_on = [helm_release.loki]
}
