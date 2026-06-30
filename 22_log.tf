resource "azurerm_log_analytics_workspace" "team63_log" {
  name                = "team63-log"
  location            = var.rgloca
  resource_group_name = var.rgname
  sku                 = "PerGB2018"
  retention_in_days   = 30
  depends_on          = [azurerm_resource_group.team603_snort_central]
}

resource "azurerm_log_analytics_workspace" "team63_log2" {
  name                = "team63-log2"
  location            = var.rgloca2
  resource_group_name = var.rgname2
  sku                 = "PerGB2018"
  retention_in_days   = 30
  depends_on          = [azurerm_resource_group.team603_snort_jpwest]
}

resource "azurerm_monitor_diagnostic_setting" "appgw_diag" {
  name                       = "appgw-diagnostic-setting"
  target_resource_id         = azurerm_application_gateway.team63_appgw.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.team63_log.id

  enabled_log {
    category_group = "AllLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "appgw_diag2" {
  name                       = "appgw-diagnostic-setting2"
  target_resource_id         = azurerm_application_gateway.team63_appgw2.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.team63_log2.id

  enabled_log {
    category_group = "AllLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
