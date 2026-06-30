resource "azurerm_virtual_network_peering" "team63_peer1to2" {
  name                      = "peer1to2"
  resource_group_name       = azurerm_resource_group.team603_snort_central.name
  virtual_network_name      = azurerm_virtual_network.team63_vnet1.name
  remote_virtual_network_id = azurerm_virtual_network.team63_vnet2.id
  depends_on                = [azurerm_virtual_network_gateway.vng]
}

resource "azurerm_virtual_network_peering" "team63_peer2to1" {
  name                      = "peer2to1"
  resource_group_name       = azurerm_resource_group.team603_snort_jpwest.name
  virtual_network_name      = azurerm_virtual_network.team63_vnet2.name
  remote_virtual_network_id = azurerm_virtual_network.team63_vnet1.id
  depends_on                = [azurerm_virtual_network_gateway.vng]
}
