# ============================================
# AKS
# ============================================

output "aks_cluster_name" {
  description = "Nome do cluster AKS"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_kube_config_command" {
  description = "Comando pra configurar o kubectl"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.aks.name}"
}

output "aks_node_resource_group" {
  description = "Resource group gerenciado pelo AKS (VMSS, discos, load balancers) — é onde o Velero precisa de permissão pra tirar snapshot"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

# ============================================
# ACR
# ============================================

output "acr_login_server" {
  description = "URL do login do ACR"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "Usuário admin do ACR"
  value       = azurerm_container_registry.acr.admin_username
}

output "acr_admin_password" {
  description = "Senha admin do ACR"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

# ============================================
# PostgreSQL Connection Strings
# ============================================

output "postgres_ngo_host" {
  description = "Host do PostgreSQL do ngo-service"
  value       = var.deploy_databases ? azurerm_postgresql_flexible_server.ngo[0].fqdn : null
}

output "postgres_ngo_connection_string" {
  description = "Connection string do PostgreSQL do ngo-service"
  value       = var.deploy_databases ? "postgres://${var.postgres_admin_user}:${var.postgres_admin_password}@${azurerm_postgresql_flexible_server.ngo[0].fqdn}:5432/ngo_db?sslmode=require" : null
  sensitive   = true
}

output "postgres_donation_host" {
  description = "Host do PostgreSQL do donation-service"
  value       = var.deploy_databases ? azurerm_postgresql_flexible_server.donation[0].fqdn : null
}

output "postgres_donation_connection_string" {
  description = "Connection string do PostgreSQL do donation-service"
  value       = var.deploy_databases ? "postgres://${var.postgres_admin_user}:${var.postgres_admin_password}@${azurerm_postgresql_flexible_server.donation[0].fqdn}:5432/donation_db?sslmode=require" : null
  sensitive   = true
}

# ============================================
# Service Bus
# ============================================

output "servicebus_namespace" {
  description = "Namespace do Service Bus"
  value       = var.deploy_databases ? azurerm_servicebus_namespace.main[0].name : null
}

output "servicebus_connection_string" {
  description = "Connection string do Service Bus"
  value       = var.deploy_databases ? azurerm_servicebus_namespace.main[0].default_primary_connection_string : null
  sensitive   = true
}

output "servicebus_queue_name" {
  description = "Nome da fila de eventos de doação"
  value       = var.deploy_databases ? azurerm_servicebus_queue.donation_events[0].name : null
}

# ============================================
# Cosmos DB
# ============================================

output "cosmosdb_account_name" {
  description = "Nome da conta Cosmos DB"
  value       = var.deploy_databases ? azurerm_cosmosdb_account.main[0].name : null
}

output "cosmosdb_connection_string" {
  description = "Connection string do Cosmos DB (Table API)"
  value       = var.deploy_databases ? "DefaultEndpointsProtocol=https;AccountName=${azurerm_cosmosdb_account.main[0].name};AccountKey=${azurerm_cosmosdb_account.main[0].primary_key};TableEndpoint=https://${azurerm_cosmosdb_account.main[0].name}.table.cosmos.azure.com:443/;" : null
  sensitive   = true
}

output "cosmosdb_volunteers_table" {
  description = "Tabela de voluntários"
  value       = var.deploy_databases ? azurerm_cosmosdb_table.volunteers[0].name : null
}

output "cosmosdb_donation_notifications_table" {
  description = "Tabela de notificações de doação"
  value       = var.deploy_databases ? azurerm_cosmosdb_table.donation_notifications[0].name : null
}

# ============================================
# Disaster Recovery (Velero)
# ============================================

output "velero_storage_account_name" {
  description = "Storage Account de backup do Velero"
  value       = var.deploy_databases ? azurerm_storage_account.velero[0].name : null
}

output "velero_storage_container_name" {
  description = "Container de backup do Velero"
  value       = var.deploy_databases ? azurerm_storage_container.velero_backups[0].name : null
}

output "velero_storage_account_key" {
  description = "Access key do Storage Account do Velero"
  value       = var.deploy_databases ? azurerm_storage_account.velero[0].primary_access_key : null
  sensitive   = true
}

output "velero_service_principal_client_id" {
  description = "Client ID do Service Principal do Velero"
  value       = var.deploy_databases ? azuread_application.velero[0].client_id : null
}

output "velero_service_principal_client_secret" {
  description = "Client secret do Service Principal do Velero"
  value       = var.deploy_databases ? azuread_service_principal_password.velero[0].value : null
  sensitive   = true
}

output "velero_tenant_id" {
  description = "Tenant ID do Azure AD (usado no credentials file do Velero)"
  value       = data.azuread_client_config.current.tenant_id
}

# ============================================
# Resource Group
# ============================================

output "resource_group_name" {
  description = "Nome do resource group principal"
  value       = azurerm_resource_group.main.name
}

# ============================================
# ArgoCD
# ============================================

output "argocd_namespace" {
  description = "Namespace do ArgoCD"
  value       = helm_release.argocd.namespace
}

output "argocd_initial_admin_password_command" {
  description = "Comando pra obter a senha inicial do admin do ArgoCD"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

# ============================================
# Ingress NGINX
# ============================================

output "ingress_nginx_namespace" {
  description = "Namespace do Ingress NGINX"
  value       = helm_release.ingress_nginx.namespace
}

output "ingress_nginx_get_ip_command" {
  description = "Comando pra obter o IP externo do Ingress NGINX"
  value       = "kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
}

# ============================================
# Observabilidade / SRE / ITSM
# ============================================

output "datadog_monitor_ids" {
  description = "IDs dos Datadog Monitors de taxa de erros 5xx, por serviço"
  value       = { for k, m in datadog_monitor.http_5xx_error_rate : k => m.id }
}

output "datadog_latency_monitor_ids" {
  description = "IDs dos Datadog Monitors de latência p95, por serviço"
  value       = { for k, m in datadog_monitor.latency_p95 : k => m.id }
}

output "pagerduty_escalation_policy_url" {
  description = "URL da Escalation Policy no PagerDuty"
  value       = "https://app.pagerduty.com/escalation_policies/${pagerduty_escalation_policy.solidarytech.id}"
}

output "pagerduty_service_urls" {
  description = "URLs dos Services no PagerDuty, por microsserviço"
  value       = { for k, s in pagerduty_service.svc : k => "https://app.pagerduty.com/service-directory/${s.id}" }
}
