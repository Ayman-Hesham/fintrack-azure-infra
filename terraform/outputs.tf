# ─── Cluster ─────────────────────────────────────────────────
output "resource_group" {
  value = azurerm_resource_group.main.name
}

output "location" {
  value = var.azure_location
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "cluster_endpoint" {
  value     = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive = true
}

# ─── Container Registry ─────────────────────────────────────
output "acr_login_server" {
  value       = azurerm_container_registry.main.login_server
  description = "ACR login server URL for docker push/pull"
}

output "acr_frontend_image" {
  value = "${azurerm_container_registry.main.login_server}/${var.project_name}/frontend"
}

output "acr_backend_image" {
  value = "${azurerm_container_registry.main.login_server}/${var.project_name}/backend"
}

# ─── Database ────────────────────────────────────────────────
output "postgresql_fqdn" {
  value     = azurerm_postgresql_flexible_server.main.fqdn
  sensitive = true
}

output "postgresql_admin_username" {
  value     = azurerm_postgresql_flexible_server.main.administrator_login
  sensitive = true
}

# ─── CI/CD ───────────────────────────────────────────────────
output "github_actions_client_id" {
  value       = azuread_application.github_actions.client_id
  description = "Add to GitHub secrets as AZURE_CLIENT_ID"
}

output "github_actions_tenant_id" {
  value       = data.azurerm_client_config.current.tenant_id
  description = "Add to GitHub secrets as AZURE_TENANT_ID"
}

output "github_actions_subscription_id" {
  value       = data.azurerm_subscription.current.subscription_id
  description = "Add to GitHub secrets as AZURE_SUBSCRIPTION_ID"
}

# ─── Workload Identity ──────────────────────────────────────
output "external_secrets_client_id" {
  value       = azurerm_user_assigned_identity.external_secrets.client_id
  description = "Update k8s/base/external-secrets/serviceaccount.yaml with this value"
}

output "loki_identity_client_id" {
  value = azurerm_user_assigned_identity.loki.client_id
}

# ─── Access Commands ─────────────────────────────────────────
output "configure_kubectl" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
}

output "acr_login" {
  value = "az acr login --name ${azurerm_container_registry.main.name}"
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "key_vault_url" {
  value       = azurerm_key_vault.main.vault_uri
  description = "The URI of the Key Vault. Use this to update vaultUrl in k8s/base/external-secrets/secret-store.yaml"
}

output "app_gateway_public_ip" {
  value       = azurerm_public_ip.appgw.ip_address
  description = "Application Gateway public IP — your app is accessible here"
}

output "access_urls" {
  description = "Quick access commands for all services"
  value = {
    app_gateway  = "Application accessible at http://${azurerm_public_ip.appgw.ip_address}"
    argocd       = "kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
    grafana      = "kubectl get svc kube-prometheus-stack-grafana -n observability -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
    alertmanager = "kubectl get svc kube-prometheus-stack-alertmanager -n observability -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
  }
}

output "argocd_initial_password" {
  value     = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  sensitive = true
}

output "estimated_hourly_cost" {
  value = "~$0.40-0.70/hour (AKS free tier + Standard_B2s nodes + B_Standard_B1ms PG + AppGW Standard_v2 autoscale 0-2)"
}
