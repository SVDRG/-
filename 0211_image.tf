resource "azurerm_managed_disk" "team63_disk" {
  name                 = "team63-disk"
  location             = var.rgloca
  resource_group_name  = var.rgname
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Copy"
  disk_size_gb         = 10
  source_resource_id   = azurerm_linux_virtual_machine.team63_vmbas.os_disk[0].id
  depends_on           = [azurerm_linux_virtual_machine.team63_vmbas]
}

resource "azurerm_image" "team63_image" {
  name                = "team63-image"
  location            = var.rgloca
  resource_group_name = var.rgname
  hyper_v_generation  = "V2"

  os_disk {
    managed_disk_id = azurerm_managed_disk.team63_disk.id
    os_type         = "Linux"
    os_state        = "Generalized"
    caching         = "ReadWrite"
    storage_type    = "StandardSSD_LRS"
  }
  depends_on = [azurerm_managed_disk.team63_disk]
}

resource "azurerm_shared_image_gallery" "team63_gallery" {
  name                = "team63imggallery"
  location            = var.rgloca
  resource_group_name = var.rgname
  depends_on          = [azurerm_resource_group.team603_snort_central]
}

resource "azurerm_shared_image" "team63_image" {
  name                         = "team63-image"
  gallery_name                 = azurerm_shared_image_gallery.team63_gallery.name
  location                     = var.rgloca
  resource_group_name          = var.rgname
  os_type                      = "Linux"
  hyper_v_generation           = "V2"
  architecture                 = "x64"
  min_recommended_vcpu_count   = 1
  max_recommended_vcpu_count   = 1
  min_recommended_memory_in_gb = 2
  max_recommended_memory_in_gb = 4

  identifier {
    publisher = "resf"
    offer     = "rockylinux-x86_64"
    sku       = "9-lvm"
  }
}

resource "azurerm_shared_image_version" "team63_version" {
  name                = "1.0.0"
  gallery_name        = azurerm_shared_image_gallery.team63_gallery.name
  location            = var.rgloca
  resource_group_name = var.rgname
  image_name          = azurerm_shared_image.team63_image.name
  managed_image_id    = azurerm_image.team63_image.id

  target_region {
    name                   = "koreacentral"
    regional_replica_count = 1
    storage_account_type   = "Standard_LRS"
  }
}

resource "azurerm_managed_disk" "team63_disk2" {
  name                 = "team63-disk2"
  location             = var.rgloca2
  resource_group_name  = var.rgname2
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Copy"
  disk_size_gb         = 10
  source_resource_id   = azurerm_linux_virtual_machine.team63_vmbas2.os_disk[0].id
  depends_on           = [azurerm_linux_virtual_machine.team63_vmbas2]
}

resource "azurerm_image" "team63_image2" {
  name                = "team63-image2"
  location            = var.rgloca2
  resource_group_name = var.rgname2
  hyper_v_generation  = "V2"

  os_disk {
    managed_disk_id = azurerm_managed_disk.team63_disk2.id
    os_type         = "Linux"
    os_state        = "Generalized"
    caching         = "ReadWrite"
    storage_type    = "StandardSSD_LRS"
  }
  depends_on = [azurerm_managed_disk.team63_disk2]
}

resource "azurerm_shared_image_gallery" "team63_gallery2" {
  name                = "team63imggallery2"
  location            = var.rgloca2
  resource_group_name = var.rgname2
  depends_on          = [azurerm_resource_group.team603_snort_jpwest]
}

resource "azurerm_shared_image" "team63_image2" {
  name                         = "team63-image2"
  gallery_name                 = azurerm_shared_image_gallery.team63_gallery2.name
  location                     = var.rgloca2
  resource_group_name          = var.rgname2
  os_type                      = "Linux"
  hyper_v_generation           = "V2"
  architecture                 = "x64"
  min_recommended_vcpu_count   = 1
  max_recommended_vcpu_count   = 1
  min_recommended_memory_in_gb = 2
  max_recommended_memory_in_gb = 4

  identifier {
    publisher = "resf"
    offer     = "rockylinux-x86_64"
    sku       = "9-lvm"
  }
}

resource "azurerm_shared_image_version" "team63_version2" {
  name                = "1.0.0"
  gallery_name        = azurerm_shared_image_gallery.team63_gallery2.name
  location            = var.rgloca2
  resource_group_name = var.rgname2
  image_name          = azurerm_shared_image.team63_image2.name
  managed_image_id    = azurerm_image.team63_image2.id

  target_region {
    name                   = "japanwest"
    regional_replica_count = 1
    storage_account_type   = "Standard_LRS"
  }
}
