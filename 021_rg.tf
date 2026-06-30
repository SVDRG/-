resource "azurerm_resource_group" "team603_snort_central" {
  name     = "team603-snort-central"
  location = "KoreaCentral"
}

resource "azurerm_resource_group" "team603_snort_jpwest" {
  name     = "team603-snort-jpwest"
  location = "JapanWest"
}

resource "azurerm_resource_group" "team603_rg_south" {
  name     = "team603_rg_south"
  location = "KoreaSouth"
}
