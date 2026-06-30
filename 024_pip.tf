resource "azurerm_public_ip" "team63_baspip" {
  name                = "team63-baspip"
  resource_group_name = var.rgname
  location            = var.rgloca
  allocation_method   = "Static"
  depends_on          = [azurerm_resource_group.team603_snort_central]
}

resource "azurerm_public_ip" "team63_appgwpip" {
  name                = "team63-appgwpip"
  resource_group_name = var.rgname
  location            = var.rgloca
  allocation_method   = "Static"
  domain_name_label   = "team63-appgw"
  depends_on          = [azurerm_resource_group.team603_snort_central]
}

resource "azurerm_public_ip" "team63_natgwpip" {
  name                = "team63-natgwpip"
  resource_group_name = var.rgname
  location            = var.rgloca
  allocation_method   = "Static"
  depends_on          = [azurerm_resource_group.team603_snort_central]
}

resource "azurerm_public_ip" "team63_gw_pip" {
  name                = "team63-gw-pip"
  location            = var.rgloca
  resource_group_name = var.rgname
  allocation_method   = "Static"
  zones               = ["1", "2", "3"]
  depends_on          = [azurerm_resource_group.team603_snort_central]
}

resource "azurerm_public_ip" "team63_bas2pip" {
  name                = "team63-bas2pip"
  resource_group_name = var.rgname2
  location            = var.rgloca2
  allocation_method   = "Static"
  depends_on          = [azurerm_resource_group.team603_snort_jpwest]
}

resource "azurerm_public_ip" "team63_appgw2pip" {
  name                = "team63-appgw2pip"
  resource_group_name = var.rgname2
  location            = var.rgloca2
  allocation_method   = "Static"
  domain_name_label   = "team63-appgw2"
  depends_on          = [azurerm_resource_group.team603_snort_jpwest]
}

resource "azurerm_public_ip" "team63_natgw2pip" {
  name                = "team63-natgw2pip"
  resource_group_name = var.rgname2
  location            = var.rgloca2
  allocation_method   = "Static"
  depends_on          = [azurerm_resource_group.team603_snort_jpwest]
}

resource "azurerm_public_ip" "team63_gw2_pip" {
  name                = "team63-gw2-pip"
  location            = var.rgloca2
  resource_group_name = var.rgname2
  allocation_method   = "Static"
  zones               = ["1", "2", "3"]
  depends_on          = [azurerm_resource_group.team603_snort_jpwest]
}

output "bastion2_ip" {
  value = azurerm_public_ip.team63_bas2pip.ip_address
}

output "appgw2_ip" {
  value = azurerm_public_ip.team63_appgw2pip.ip_address
}

output "natgw2_ip" {
  value = azurerm_public_ip.team63_natgw2pip.ip_address
}


output "bastion_ip" {
  value = azurerm_public_ip.team63_baspip.ip_address
}

output "appgw_ip" {
  value = azurerm_public_ip.team63_appgwpip.ip_address
}

output "natgw_ip" {
  value = azurerm_public_ip.team63_natgwpip.ip_address
}

output "gw_pip" {
  value = azurerm_public_ip.team63_gw_pip.ip_address
}

output "gw2_pip" {
  value = azurerm_public_ip.team63_gw2_pip.ip_address
}