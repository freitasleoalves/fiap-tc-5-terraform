locals {
  prefix = "${var.project_name}-${var.environment}"

  # ------------------------------------------------------------------
  # FinOps: Estratégia de Tagging (requisito obrigatório da Fase 5)
  # ------------------------------------------------------------------
  # Tags obrigatórias exigidas no desafio, aplicadas em 100% dos recursos
  # de nuvem via `local.tags` (ou `merge(local.tags, {...})` quando o
  # recurso precisa de uma tag extra, ex.: Component). Isso é o que
  # sustenta a análise de custo por projeto/ambiente/centro de custo no
  # Cost Management do Azure (ver README para o comando usado no
  # relatório de Forecast).
  mandatory_tags = {
    Project     = "SolidaryTech"
    Environment = "Production"
    CostCenter  = "NGO-Core"
  }

  tags = merge(local.mandatory_tags, {
    ManagedBy = "terraform"
    Fase      = "5"
  })
}

# ============================================
# Resource Group
# ============================================

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.prefix}"
  location = var.location
  tags     = merge(local.tags, { Component = "core" })
}
