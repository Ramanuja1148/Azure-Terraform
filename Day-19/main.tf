
# Terraform Provisioners Demonstration

# Resource Group
resource "azurerm_resource_group" "app_rg" {
  name     = "provisioner-demo-rg"
  location = "koreacentral"
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "demo-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
}

# Subnet
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.app_rg.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "vm-nsg"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


# Public IP
resource "azurerm_public_ip" "vm_ip" {
  name                = "demo-public-ip"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  allocation_method   = "Static"
}

# Network Interface
resource "azurerm_network_interface" "main" {
  name                = "demo-nic"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "null_resource" "deployment_prep" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "echo Deployment started > deployment-${replace(timestamp(), ":", "-")}.log"

  }
}


# Virtual Machine
resource "azurerm_linux_virtual_machine" "demo_vm" {
  name                  = "demo-vm"
  location              = azurerm_resource_group.app_rg.location
  resource_group_name   = azurerm_resource_group.app_rg.name
  network_interface_ids = [azurerm_network_interface.main.id]
  size                  = "Standard_D2s_v3"

 depends_on = [ null_resource.deployment_prep ]
 

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "demovm"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  provisioner "remote-exec" {
    inline = [   
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      
      # Create a sample welcome page
      "echo '<html><body><h1>#28daysofAZTerraform is Awesome!</h1></body></html>' | sudo tee /var/www/html/index.html",
      
      # Ensure nginx is running
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx" ]

      connection {
        type = "ssh"
        user = "azureuser"
        private_key = file("~/.ssh/id_rsa")
        host = azurerm_public_ip.vm_ip.ip_address
      }
    
  }

  provisioner "file" {
    source = "configs/sample.conf"
    destination = "/home/azureuser/sample.conf"

    connection {
        type = "ssh"
        user = "azureuser"
        private_key = file("~/.ssh/id_rsa")
        host = azurerm_public_ip.vm_ip.ip_address
      }
    
  }

}


# Outputs
output "vm_public_ip" {
  value = azurerm_public_ip.vm_ip.ip_address
}
