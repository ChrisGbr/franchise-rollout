provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg_berlin" {
  name     = "rg-franchise-berlin01"
  location = "GermanyWestCentral"
}

resource "azurerm_virtual_network" "vnet_berlin" {
  name                = "vnet-berlin01"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.rg_berlin.location
  resource_group_name = azurerm_resource_group.rg_berlin.name
}

resource "azurerm_subnet" "subnet_berlin" {
  name                 = "subnet-berlin01"
  resource_group_name  = azurerm_resource_group.rg_berlin.name
  virtual_network_name = azurerm_virtual_network.vnet_berlin.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_security_group" "nsg_berlin" {
  name                = "nsg-berlin01"
  location            = azurerm_resource_group.rg_berlin.location
  resource_group_name = azurerm_resource_group.rg_berlin.name

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "pip_berlin" {
  name                = "pip-berlin01"
  location            = azurerm_resource_group.rg_berlin.location
  resource_group_name = azurerm_resource_group.rg_berlin.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "nic_berlin" {
  name                = "nic-berlin01"
  location            = azurerm_resource_group.rg_berlin.location
  resource_group_name = azurerm_resource_group.rg_berlin.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_berlin.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_berlin.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc_berlin" {
  network_interface_id      = azurerm_network_interface.nic_berlin.id
  network_security_group_id = azurerm_network_security_group.nsg_berlin.id
}

resource "azurerm_windows_virtual_machine" "vm_berlin" {
  name                  = "vm-ad-berlin01"
  resource_group_name   = azurerm_resource_group.rg_berlin.name
  location              = azurerm_resource_group.rg_berlin.location
  size                  = "Standard_D2s_v3"
  admin_username        = "franchiseadmin"
  admin_password        = "P@ssw0rd123!"
  network_interface_ids = [azurerm_network_interface.nic_berlin.id]
  provision_vm_agent    = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

output "public_ip_address_berlin" {
  value = azurerm_public_ip.pip_berlin.ip_address
}
