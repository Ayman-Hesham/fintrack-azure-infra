resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.9.11"
  namespace  = "kube-system"

  values = [yamlencode({
    installCRDs = true
  })]

  depends_on = [azurerm_kubernetes_cluster.main]
}
