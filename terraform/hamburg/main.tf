provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg_hamburg" {
  name     = "rg-franchise-hamburg01"
  location = "GermanyNorth"
}

resource "azurerm_virtual_network" "vnet_hamburg" {
  name                = "vnet-hamburg01"
  address_space       = ["10.11.0.0/16"]
  location            = azurerm_resource_group.rg_hamburg.location
  resource_group_name = azurerm_resource_group.rg_hamburg.name
}

resource "azurerm_subnet" "subnet_hamburg" {
  name                 = "subnet-hamburg01"
  resource_group_name  = azurerm_resource_group.rg_hamburg.name
  virtual_network_name = azurerm_virtual_network.vnet_hamburg.name
  address_prefixes     = ["10.11.0.0/24"]
}

resource "azurerm_network_security_group" "nsg_hamburg" {
  name                = "nsg-hamburg01"
  location            = azurerm_resource_group.rg_hamburg.location
  resource_group_name = azurerm_resource_group.rg_hamburg.name

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

resource "azurerm_public_ip" "pip_hamburg" {
  name                = "pip-hamburg01"
  location            = azurerm_resource_group.rg_hamburg.location
  resource_group_name = azurerm_resource_group.rg_hamburg.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "nic_hamburg" {
  name                = "nic-hamburg01"
  location            = azurerm_resource_group.rg_hamburg.location
  resource_group_name = azurerm_resource_group.rg_hamburg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_hamburg.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_hamburg.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc_hamburg" {
  network_interface_id      = azurerm_network_interface.nic_hamburg.id
  network_security_group_id = azurerm_network_security_group.nsg_hamburg.id
}

resource "azurerm_windows_virtual_machine" "vm_hamburg" {
  name                = "vm-ad-hamburg01"
  location            = azurerm_resource_group.rg_hamburg.location
  resource_group_name = azurerm_resource_group.rg_hamburg.name
  size                = "Standard_D2s_v3"
  admin_username      = "franchiseadmin"
  admin_password      = "P@ssw0rd123!"
  network_interface_ids = [azurerm_network_interface.nic_hamburg.id]
  provision_vm_agent  = true

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

output "public_ip_address_hamburg" {
  value = azurerm_public_ip.pip_hamburg.ip_address
}
