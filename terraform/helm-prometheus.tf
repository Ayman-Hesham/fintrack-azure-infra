resource "helm_release" "prometheus" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "55.5.0"
  namespace  = kubernetes_namespace.observability.metadata[0].name

  values = [yamlencode({
    prometheus = {
      prometheusSpec = {
        replicas  = 1
        retention = "3h"
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              accessModes = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = "5Gi"
                }
              }
            }
          }
        }
        additionalScrapeConfigs = []
      }
    }
    grafana = {
      adminPassword = "admin"
      replicas      = 1
      service = {
        type = "LoadBalancer"
      }
      additionalDataSources = [{
        name      = "Alertmanager"
        type      = "alertmanager"
        url       = "http://kube-prometheus-stack-alertmanager.observability.svc.cluster.local:9093"
        access    = "proxy"
        isDefault = false
      }]
    }
    alertmanager = {
      enabled = true
      alertmanagerSpec = {
        replicas = 1
        storage = {
          volumeClaimTemplate = {
            spec = {
              accessModes = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = "2Gi"
                }
              }
            }
          }
        }
      }
      service = {
        type = "LoadBalancer"
      }
      config = {
        global = {
          resolve_timeout    = "5m"
          smtp_smarthost     = "smtp.gmail.com:587"
          smtp_from          = "aymanhesham249@gmail.com"
          smtp_auth_username = "aymanhesham249@gmail.com"
          smtp_auth_password = var.alertmanager_smtp_password
          smtp_require_tls   = true
        }
        route = {
          group_by        = ["alertname", "cluster", "service"]
          group_wait      = "10s"
          group_interval  = "10s"
          repeat_interval = "12h"
          receiver        = "email-receiver"
        }
        receivers = [
          {
            name = "null"
          },
          {
            name = "email-receiver"
            email_configs = [{
              to            = "aymanhesham249@gmail.com"
              send_resolved = true
            }]
          }
        ]
      }
    }
    defaultRules = {
      create = true
      rules = {
        alertmanager                = true
        etcd                        = false
        configReloaders             = true
        general                     = true
        k8s                         = true
        kubeApiserverAvailability   = true
        kubeApiserverBurnrate       = false
        kubeApiserverHistogram      = false
        kubeApiserverSlos           = false
        kubeControllerManager       = false
        kubelet                     = true
        kubeProxy                   = false
        kubePrometheusGeneral       = true
        kubePrometheusNodeRecording = true
        kubernetesApps              = true
        kubernetesResources         = true
        kubernetesStorage           = true
        kubernetesSystem            = true
        kubeSchedulerAlerting       = false
        kubeSchedulerRecording      = false
        kubeStateMetrics            = true
        network                     = true
        node                        = true
        nodeExporterAlerting        = true
        nodeExporterRecording       = true
        prometheus                  = true
        prometheusOperator          = true
      }
    }
  })]

  depends_on = [kubernetes_namespace.observability]
}
