resource "azurerm_traffic_manager_profile" "team63_tm" {
  name                   = "team63-tm-profile"
  resource_group_name    = azurerm_resource_group.team603_rg_south.name
  traffic_routing_method = "Priority"
  dns_config {
    relative_name = "team63-dns"
    ttl           = 30
  }

  monitor_config {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }
}

resource "azurerm_traffic_manager_external_endpoint" "endpoint_central" {
  name                 = "epc-ext"
  profile_id           = azurerm_traffic_manager_profile.team63_tm.id
  always_serve_enabled = true
  endpoint_location    = var.rgloca
  target               = azurerm_public_ip.team63_appgwpip.ip_address
  priority             = 1
}

resource "azurerm_traffic_manager_external_endpoint" "endpoint_jpwest" {
  name                 = "eps-ext"
  profile_id           = azurerm_traffic_manager_profile.team63_tm.id
  always_serve_enabled = true
  endpoint_location    = var.rgloca2
  target               = azurerm_public_ip.team63_appgw2pip.ip_address
  priority             = 2
}
