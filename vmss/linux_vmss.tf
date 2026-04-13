terraform {
  required_providers {
    azurerm = {
        source  = "hashicorp/azurerm"
        version = "~> 4.8.0"
    }
  }
  required_version = ">=1.9.0"
}

locals {
  first_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQChtB+VT4zGl1PBzC5kVX6Y5BPEdvMVcOrlVaacLZ+XvkR3H4EJQczwb0VY5WoqP8hjN3tOKB5kpxJYWshDrj4mGYgmzMJ/LSM+R2VG5r6GzudwyD/0cl+pjaouVl0aTBJor/M05RVwZzBQ1xDhw9UdefaoAN+t0j/QLqJvDFiG5INJDPyV/34Mrv51AjN4I8WTXV0ZJF2I08FtdolpTgUChEE8I4+cMQKFK8NBNLfQdYgjRQYYZq+AoGKau2YoT3pTseCQP8P+Mvgh2RtbYlO7EjNjsGPOtze8zvRUieySE8Mm0pJ3xysUHjQeaoL9e5ZXcBhZmaQB9M6H/0aECYNzZLVRVHHSMahb8T0poQ4YVt6d/gMg0uzdWkIZ5VpGm6BHXc1KkeDC5RtdaexqF2xcEN3AXQ8PnL3QY1+0ZS5CLYUuLhv8/4h7Ywkv7IjDyl8XGTelF1f7W1djlTt28We4OVYtw0zOJ8rQvMIxx4JqOf5VaGeRDT/KdNkcqA0m3SDHxoZpLYqdiMZDtkqbxE0OcRFMkMUWOyvnCbNspUQS9+kJoD5VaF5uNgxuNg/wpx7R+pQbP3W5BDgtOGNiwrtsab7xt+HhO6VPZk8I+0VOA43iAPpNKT+25Uh+mod7ypVppynGsLrXNqpukPDJqQ/ECsFqXujUCh+B4gy3N4tkcQ== azure-vm"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "eastasia"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_linux_virtual_machine_scale_set" "example" {
  name                = "example-vmss"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard_F2"
  instances           = 1
  admin_username      = "adminuser"

  admin_ssh_key {
    username   = "adminuser"
    public_key = local.first_public_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "example"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.internal.id
    }
  }
}