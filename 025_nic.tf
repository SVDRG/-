resource "azurerm_network_interface" "team63_bas_nic" {
  name                = "team63-bas-nic"
  location            = var.rgloca
  resource_group_name = var.rgname

  ip_configuration {
    name                          = "team63-bas-nic-ip"
    subnet_id                     = azurerm_subnet.team63_bas1.id
    private_ip_address_allocation = "Static"
    private_ip_address_version    = "IPv4"
    private_ip_address            = "10.0.0.11"
    public_ip_address_id          = azurerm_public_ip.team63_baspip.id
  }
  depends_on = [ azurerm_subnet.team63_bas1 ]
}

resource "azurerm_network_interface" "team63_bas2_nic" {
  name                = "team63-bas2-nic"
  location            = var.rgloca2
  resource_group_name = var.rgname2

  ip_configuration {
    name                          = "team63-bas2-nic-ip"
    subnet_id                     = azurerm_subnet.team63_bas2.id
    private_ip_address_allocation = "Static"
    private_ip_address_version    = "IPv4"
    private_ip_address            = "172.16.0.11"
    public_ip_address_id          = azurerm_public_ip.team63_bas2pip.id
  }
  depends_on = [ azurerm_subnet.team63_bas1 ]
}
