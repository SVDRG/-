resource "azurerm_subnet" "team63_bas1" {
  name                            = "team63-bas1"
  virtual_network_name            = azurerm_virtual_network.team63_vnet1.name
  resource_group_name             = var.rgname
  address_prefixes                = ["10.0.0.0/24"]
  default_outbound_access_enabled = true
  depends_on                      = [azurerm_virtual_network.team63_vnet1]
}

resource "azurerm_subnet" "team63_appgw" {
  name                            = "team63-appgw"
  virtual_network_name            = azurerm_virtual_network.team63_vnet1.name
  resource_group_name             = var.rgname
  address_prefixes                = ["10.0.1.0/24"]
  default_outbound_access_enabled = true
  depends_on                      = [azurerm_virtual_network.team63_vnet1]
}

resource "azurerm_subnet" "team63_scale" {
  name                            = "team63-scale"
  virtual_network_name            = azurerm_virtual_network.team63_vnet1.name
  resource_group_name             = var.rgname
  address_prefixes                = ["10.0.2.0/24"]
  default_outbound_access_enabled = false
  depends_on                      = [azurerm_virtual_network.team63_vnet1]
}

resource "azurerm_subnet" "team63_ng" {
  name                            = "GatewaySubnet"
  virtual_network_name            = azurerm_virtual_network.team63_vnet1.name
  resource_group_name             = var.rgname
  address_prefixes                = ["10.0.3.0/24"]
  default_outbound_access_enabled = true
  depends_on                      = [azurerm_virtual_network.team63_vnet1]
}

resource "azurerm_subnet" "team63_bas2" {
  name                            = "team63-bas2"
  virtual_network_name            = azurerm_virtual_network.team63_vnet2.name
  resource_group_name             = var.rgname2
  address_prefixes                = ["172.16.0.0/24"]
  default_outbound_access_enabled = true
  depends_on                      = [azurerm_virtual_network.team63_vnet2]
}

resource "azurerm_subnet" "team63_appgw2" {
  name                            = "team63-appgw2"
  virtual_network_name            = azurerm_virtual_network.team63_vnet2.name
  resource_group_name             = var.rgname2
  address_prefixes                = ["172.16.1.0/24"]
  default_outbound_access_enabled = true
  depends_on                      = [azurerm_virtual_network.team63_vnet2]
}

resource "azurerm_subnet" "team63_scale2" {
  name                            = "team63-scale2"
  virtual_network_name            = azurerm_virtual_network.team63_vnet2.name
  resource_group_name             = var.rgname2
  address_prefixes                = ["172.16.2.0/24"]
  default_outbound_access_enabled = false
  depends_on                      = [azurerm_virtual_network.team63_vnet2]
}

resource "azurerm_subnet" "team63_ng2" {
  name                            = "GatewaySubnet"
  virtual_network_name            = azurerm_virtual_network.team63_vnet2.name
  resource_group_name             = var.rgname2
  address_prefixes                = ["172.16.3.0/24"]
  default_outbound_access_enabled = true
  depends_on                      = [azurerm_virtual_network.team63_vnet2]
}
