resource "azurerm_virtual_network" "team63_vnet1" {
  name                = "team63-vnet1"
  address_space       = ["10.0.0.0/16"]
  location            = var.rgloca
  resource_group_name = var.rgname
  depends_on          = [azurerm_resource_group.team603_snort_central]
}

resource "azurerm_virtual_network" "team63_vnet2" {
  name                = "team63-vnet2"
  address_space       = ["172.16.0.0/16"]
  location            = var.rgloca2
  resource_group_name = var.rgname2
  depends_on          = [azurerm_resource_group.team603_snort_jpwest]
}
