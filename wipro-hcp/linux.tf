terraform {
  required_providers {
    azurerm = {
        source  = "hashicorp/azurerm"
        version = "~> 4.8.0"
    }
  }
  required_version = ">=1.9.0"
}

provider "azurerm" {
  features {
    
  }
  subscription_id = "1640771f-7313-4da9-8edd-cdc73607d2f6"
  tenant_id = "2a5987b0-dd28-476f-952b-89f862599692"
}

resource "azurerm_resource_group" "rg" {
    name     = "HCP-RG"
    location = "centralindia"
}

resource "azurerm_virtual_network" "rg" {
    name                = "HCP-VNET"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "rg" {
    name                 = "HCP-SUBNET"
    address_prefixes     = ["10.0.0.0/24"]
    virtual_network_name = azurerm_virtual_network.rg.name
    resource_group_name  = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "rg" {
  name                = "HCP-NSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "rg" {
    name                = "HCP-PUBLIC-IP"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method   = "Static"
  
}
resource "azurerm_network_interface" "rg" {
    name                = "HCP-NIC"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.rg.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.rg.id
    } 
}

resource "azurerm_network_interface_security_group_association" "rg" {
  network_interface_id      = azurerm_network_interface.rg.id
  network_security_group_id = azurerm_network_security_group.rg.id
}

resource "azurerm_linux_virtual_machine" "rg" {
    name                  = "HCP-UBUNTU-VM"
    resource_group_name   = azurerm_resource_group.rg.name
    location              = azurerm_resource_group.rg.location
    size                  = "Standard_D4s_v3"
    admin_username        = "azureuser"
    network_interface_ids = [
        azurerm_network_interface.rg.id
    ]
    admin_ssh_key {
        username   = "azureuser"
        public_key = file("C:/Users/raman/.ssh/id_rsa.pub")
    }
    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }
    source_image_reference {
        publisher = "Canonical"
        offer     = "ubuntu-24_04-lts"
        sku       = "server"
        version   = "latest"
    }
}

resource "azurerm_managed_disk" "datadisk" {
  name                 = "HCP-DATA-DISK"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 64
}

resource "azurerm_virtual_machine_data_disk_attachment" "datadisk_attach" {
  managed_disk_id    = azurerm_managed_disk.datadisk.id
  virtual_machine_id = azurerm_linux_virtual_machine.rg.id
  lun                = 0
  caching            = "ReadWrite"
}
