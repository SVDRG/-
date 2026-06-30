resource "azurerm_route_table" "team63_rt" {
  name                = "team63-rt"
  location            = var.rgloca
  resource_group_name = var.rgname

  route {
    name           = "route"
    address_prefix = "192.168.10.0/24"
    next_hop_type  = "VirtualNetworkGateway"
  }

  route {
    name           = "route2"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
  depends_on = [azurerm_resource_group.team603_snort_central]
}

resource "azurerm_route_table" "team63_rt2" {
  name                = "team63-rt2"
  location            = var.rgloca2
  resource_group_name = var.rgname2

  route {
    name           = "route"
    address_prefix = "192.168.10.0/24"
    next_hop_type  = "VirtualNetworkGateway"
  }

  route {
    name           = "route2"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
  depends_on = [azurerm_resource_group.team603_snort_jpwest]
}

resource "azurerm_subnet_route_table_association" "team63_rt_assoc" {
  subnet_id      = azurerm_subnet.team63_scale.id
  route_table_id = azurerm_route_table.team63_rt.id
  depends_on     = [azurerm_route_table.team63_rt]
}

resource "azurerm_subnet_route_table_association" "team63_rt2_assoc" {
  subnet_id      = azurerm_subnet.team63_scale2.id
  route_table_id = azurerm_route_table.team63_rt2.id
  depends_on     = [azurerm_route_table.team63_rt2]
}
