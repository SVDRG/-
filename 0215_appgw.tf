# since these var are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.team63_vnet1.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.team63_vnet1.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.team63_vnet1.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.team63_vnet1.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.team63_vnet1.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.team63_vnet1.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.team63_vnet1.name}-rdrcfg"
}

resource "azurerm_application_gateway" "team63_appgw" {
  name                = "team63-appgw"
  resource_group_name = var.rgname
  location            = var.rgloca

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.team63_appgw.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.team63_appgwpip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  probe {
    name                                      = "team63-appgw-probe"
    protocol                                  = "Http"
    port                                      = 80
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  backend_http_settings {
    name                                = local.http_setting_name
    cookie_based_affinity               = "Disabled"
    path                                = "/"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 60
    probe_name                          = "team63-appgw-probe"
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.team63_waf.id
}
