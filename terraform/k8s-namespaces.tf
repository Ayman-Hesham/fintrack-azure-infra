resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
  depends_on = [azurerm_kubernetes_cluster.main]
}

resource "kubernetes_namespace" "observability" {
  metadata {
    name = "observability"
  }
  depends_on = [azurerm_kubernetes_cluster.main]
}

resource "kubernetes_namespace" "application" {
  metadata {
    name = "application"
  }
  depends_on = [azurerm_kubernetes_cluster.main]
}
