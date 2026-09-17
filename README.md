# SolidaryTech — Terraform (Fase 5 / Hackathon)

IaC completo do ecossistema SolidaryTech: cluster AKS, ACR, redes,
bancos de dados dos 3 microsserviços + notification-service, mensageria,
backend de Disaster Recovery (Velero) e toda a stack de Alertas
Inteligentes / ITSM (Datadog + PagerDuty + Discord + Self-Healing).

Segue o mesmo padrão validado nas Fases 3/4 do ToggleMaster, adaptado
para os requisitos novos da Fase 5 (FinOps, SRE, DR).

## Arquitetura

```
main.tf         Resource Group + tags FinOps obrigatórias
providers.tf    azurerm, azuread, helm, datadog, pagerduty + backend remoto
network.tf      VNet + Subnet
aks.tf          AKS + ACR
argocd.tf       ArgoCD + Ingress NGINX (via Helm)
postgresql.tf   Postgres Flexible Server: ngo_db, donation_db
servicebus.tf   Fila donation-events (substitui o SQS do código original)
cosmosdb.tf     Table API: Volunteers, DonationNotifications (substitui o
                DynamoDB do código original)
velero.tf       Storage Account + Service Principal para backup do Velero
datadog.tf      Monitors (taxa de erro + latência p95), Webhooks
                (Discord/self-healing), integração PagerDuty
pagerduty.tf    Escalation Policy + Services + integração Datadog
variables.tf / outputs.tf
```

## FinOps: tagging obrigatório

Todo recurso carrega, no mínimo:

```
Project     = "SolidaryTech"
Environment = "Production"
CostCenter  = "NGO-Core"
ManagedBy   = "terraform"
Fase        = "5"
Component   = "<específico do recurso, ex.: aks, ngo-service, disaster-recovery>"
```

Definido em `local.tags` (`main.tf`) e aplicado via `merge(local.tags, {...})`
em 100% dos recursos — é a base do relatório de Forecast de custos (ver
`az rest` contra `Microsoft.CostManagement/query`, mesma técnica usada no
fim da Fase 4 pra listar os maiores ofensores financeiros).

## Disaster Recovery (Velero)

Este repositório só provisiona o **backend** (Storage Account + Service
Principal com permissão de Blob + snapshot de disco no node resource group
do AKS). O Velero em si (Helm chart + `BackupStorageLocation` + `Schedule`)
é instalado via GitOps, no repositório `fiap-tc-5-gitops`
(`addons/velero/`), consumindo as credenciais geradas aqui
(`velero_service_principal_client_id`, `velero_service_principal_client_secret`,
`velero_tenant_id`, `velero_storage_account_name`) como um Secret do
Kubernetes.

**RTO/RPO** (formalizados no PCN — ver relatório de entrega):

| Serviço | RPO | RTO |
|---|---|---|
| `donation-service` (Hot Path) | ≤ 5 min (via PITR do Postgres) | ≤ 30 min |
| Demais serviços | ≤ 15 min | ≤ 2 horas |

## Início rápido

```bash
az login
terraform init
cp terraform.tfvars.example terraform.tfvars   # preencha com valores reais
terraform plan -out=tfplan
terraform apply tfplan
```

Com `deploy_databases = false` (padrão), só sobe cluster + ArgoCD +
Ingress + Monitors/PagerDuty — nada de banco, mensageria ou Velero (economia
enquanto valida a stack de observabilidade). Ligue quando for provisionar
o ambiente completo.

## Self-Healing: uma peculiaridade desta fase

Diferente da Fase 4 (onde o workflow de self-healing morava no repositório
GitOps), aqui **cada microsserviço tem seu próprio repositório** — então
o webhook de self-healing do Datadog (`datadog.tf`) aponta para o repo do
serviço específico (`var.service_repos`), não para o `fiap-tc-5-gitops`.
Cada repositório de serviço precisa ter seu próprio
`.github/workflows/self-heal.yml` (ver Fase C do plano de execução) e os
secrets `AZURE_CREDENTIALS`, `AKS_RESOURCE_GROUP`, `AKS_CLUSTER_NAME`
configurados individualmente.
