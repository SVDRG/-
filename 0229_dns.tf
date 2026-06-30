resource "azurerm_dns_zone" "team63_dns" {
  name                = "svdrg.cloud"
  resource_group_name = azurerm_resource_group.team603_rg_south.name
  depends_on          = [azurerm_resource_group.team603_rg_south]
}

resource "azurerm_dns_a_record" "team63_root_cname" {
  name                = "@"
  zone_name           = azurerm_dns_zone.team63_dns.name
  resource_group_name = azurerm_resource_group.team603_rg_south.name
  ttl                 = 30
  target_resource_id  = azurerm_traffic_manager_profile.team63_tm.id
  depends_on = [
    azurerm_traffic_manager_external_endpoint.endpoint_central,
    azurerm_traffic_manager_external_endpoint.endpoint_jpwest
  ]
}

resource "azurerm_dns_cname_record" "team63_www_cname" {
  name                = "www"
  zone_name           = azurerm_dns_zone.team63_dns.name
  resource_group_name = azurerm_resource_group.team603_rg_south.name
  ttl                 = 30
  record              = azurerm_traffic_manager_profile.team63_tm.fqdn
}
