resource "azurerm_network_security_group" "team63_nsg_ssh" {
  name                = "team63-nsg-ssh"
  location            = var.rgloca
  resource_group_name = var.rgname

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22"]
    source_address_prefixes    = ["58.150.29.60","10.10.42.0/24"]
    destination_address_prefix = "*"
  }
  depends_on = [azurerm_resource_group.team603_snort_central]
}

resource "azurerm_network_security_group" "team63_nsg_ssh2" {
  name                = "team63-nsg-ssh2"
  location            = var.rgloca2
  resource_group_name = var.rgname2

  security_rule {
    name                       = "ssh2"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22"]
    source_address_prefixes    = ["58.150.29.60","10.10.42.0/24"]
    destination_address_prefix = "*"
  }
  depends_on = [azurerm_resource_group.team603_snort_jpwest]
}

resource "azurerm_network_security_group" "team63_nsg_http_mysql" {
  name                = "team63-nsg-http-mysql"
  location            = var.rgloca
  resource_group_name = var.rgname

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22"]
    source_address_prefixes    = ["58.150.29.60","10.10.42.0/24"]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "http"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "mysql"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["3306"]
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "192.168.10.11"
  }
  depends_on = [azurerm_resource_group.team603_snort_central]
}

resource "azurerm_network_security_group" "team63_nsg_http_mysql2" {
  name                = "team63-nsg-http-mysql2"
  location            = var.rgloca2
  resource_group_name = var.rgname2

  security_rule {
    name                       = "ssh2"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22"]
    source_address_prefixes    = ["58.150.29.60","10.10.42.0/24"]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "http2"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "mysql2"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["3306"]
    source_address_prefix      = "172.16.2.0/24"
    destination_address_prefix = "192.168.10.11"
  }
  depends_on = [azurerm_resource_group.team603_snort_jpwest]
}
