resource "azurerm_local_network_gateway" "home" {
  name                = "backHome"
  resource_group_name = var.rgname
  location            = var.rgloca
  gateway_address     = "1.220.76.4"
  address_space       = ["192.168.30.0/29"]
  bgp_settings {
    asn                 = 65000
    bgp_peering_address = "169.254.21.1"
  }
  depends_on = [azurerm_resource_group.team603_snort_central]
}

resource "azurerm_virtual_network_gateway" "vng" {
  name                = "test"
  location            = var.rgloca
  resource_group_name = var.rgname

  type     = "Vpn"
  vpn_type = "RouteBased"

  sku        = "VpnGw1AZ"
  generation = "Generation1"
  bgp_settings {
    asn = 65001
  }

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.team63_gw_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.team63_ng.id
  }
  depends_on = [azurerm_resource_group.team603_snort_central]
}

resource "azurerm_virtual_network_gateway_connection" "onpremise" {
  name                = "onpremise"
  location            = var.rgloca
  resource_group_name = var.rgname

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vng.id
  local_network_gateway_id   = azurerm_local_network_gateway.home.id

  shared_key = var.shared_key

  ipsec_policy {
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    dh_group         = "DHGroup2"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "PFS2"
    sa_lifetime      = 3600
    sa_datasize      = 2147483647
  }
  depends_on = [azurerm_virtual_network_gateway.vng]
}

resource "azurerm_local_network_gateway" "home2" {
  name                = "backHome2"
  resource_group_name = var.rgname2
  location            = var.rgloca2
  gateway_address     = "1.220.76.4"
  address_space       = ["192.168.10.0/24"]
  bgp_settings {
    asn                 = 65000
    bgp_peering_address = "192.168.10.11"
  }
  depends_on = [azurerm_resource_group.team603_snort_jpwest]
}

resource "azurerm_virtual_network_gateway" "vng2" {
  name                = "test2"
  location            = var.rgloca2
  resource_group_name = var.rgname2

  type     = "Vpn"
  vpn_type = "RouteBased"

  sku        = "VpnGw1AZ"
  generation = "Generation1"
  bgp_settings {
    asn = 65002
  }

  ip_configuration {
    name                          = "vnetGatewayConfig2"
    public_ip_address_id          = azurerm_public_ip.team63_gw2_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.team63_ng2.id
  }
  depends_on = [azurerm_resource_group.team603_snort_jpwest]
}

resource "azurerm_virtual_network_gateway_connection" "onpremise2" {
  name                = "onpremise2"
  location            = var.rgloca2
  resource_group_name = var.rgname2

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vng2.id
  local_network_gateway_id   = azurerm_local_network_gateway.home2.id

  shared_key = var.shared_key

  ipsec_policy {
    ike_encryption   = "AES256"   # -IkeEncryption AES256
    ike_integrity    = "SHA256"   # -IkeIntegrity SHA256
    dh_group         = "DHGroup2" # -DhGroup DHGroup2
    ipsec_encryption = "AES256"   # -IpsecEncryption AES256
    ipsec_integrity  = "SHA256"   # -IpsecIntegrity SHA256
    pfs_group        = "PFS2"     # -PfsGroup PFS2
    sa_lifetime      = 3600       # -SALifeTimeSeconds 3600
    sa_datasize      = 2147483647 # -SADataSizeKilobytes 2147483647
  }
  depends_on = [azurerm_virtual_network_gateway.vng2]
}
