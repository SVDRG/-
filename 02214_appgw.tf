locals {
  backend_address_pool_name2      = "${azurerm_virtual_network.team63_vnet2.name}-beap"
  frontend_port_name2             = "${azurerm_virtual_network.team63_vnet2.name}-feport"
  frontend_ip_configuration_name2 = "${azurerm_virtual_network.team63_vnet2.name}-feip"
  http_setting_name2              = "${azurerm_virtual_network.team63_vnet2.name}-be-htst"
  listener_name2                  = "${azurerm_virtual_network.team63_vnet2.name}-httplstn"
  request_routing_rule_name2      = "${azurerm_virtual_network.team63_vnet2.name}-rqrt"
  redirect_configuration_name2    = "${azurerm_virtual_network.team63_vnet2.name}-rdrcfg"
}

resource "azurerm_application_gateway" "team63_appgw2" {
  name                = "team63-appgw2"
  resource_group_name = var.rgname2
  location            = var.rgloca2

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.team63_appgw2.id
  }

  frontend_port {
    name = local.frontend_port_name2
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name2
    public_ip_address_id = azurerm_public_ip.team63_appgw2pip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name2
  }

  probe {
    name                                      = "team63-appgw2-probe"
    protocol                                  = "Http"
    port                                      = 80
    path                                      = "/" # WordPress 메인 페이지 체크
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  backend_http_settings {
    name                                = local.http_setting_name2
    cookie_based_affinity               = "Disabled"
    path                                = "/"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 60
    probe_name                          = "team63-appgw2-probe"
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = local.listener_name2
    frontend_ip_configuration_name = local.frontend_ip_configuration_name2
    frontend_port_name             = local.frontend_port_name2
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name2
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name2
    backend_address_pool_name  = local.backend_address_pool_name2
    backend_http_settings_name = local.http_setting_name2
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.team63_waf2.id
}
