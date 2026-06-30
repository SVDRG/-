resource "azurerm_nat_gateway" "team63_natgw" {
  name                    = "team63-natgw"
  location                = var.rgloca
  resource_group_name     = var.rgname
  sku_name                = "Standard"
  idle_timeout_in_minutes = "4"
  depends_on              = [azurerm_resource_group.team603_snort_central]
}

resource "azurerm_nat_gateway_public_ip_association" "team63_natgw_pip" {
  nat_gateway_id       = azurerm_nat_gateway.team63_natgw.id
  public_ip_address_id = azurerm_public_ip.team63_natgwpip.id
}

resource "azurerm_subnet_nat_gateway_association" "team63_natscale" {
  nat_gateway_id = azurerm_nat_gateway.team63_natgw.id
  subnet_id      = azurerm_subnet.team63_scale.id
}

resource "azurerm_nat_gateway" "team63_natgw2" {
  name                    = "team63-natgw2"
  location                = var.rgloca2
  resource_group_name     = var.rgname2
  sku_name                = "Standard"
  idle_timeout_in_minutes = "4"
  depends_on              = [azurerm_resource_group.team603_snort_jpwest]
}

resource "azurerm_nat_gateway_public_ip_association" "team63_natgw2_pip" {
  nat_gateway_id       = azurerm_nat_gateway.team63_natgw2.id
  public_ip_address_id = azurerm_public_ip.team63_natgw2pip.id
}

resource "azurerm_subnet_nat_gateway_association" "team63_natscale2" {
  nat_gateway_id = azurerm_nat_gateway.team63_natgw2.id
  subnet_id      = azurerm_subnet.team63_scale2.id
}