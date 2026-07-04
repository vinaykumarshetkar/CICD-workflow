terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.77.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "taskRG" {
  name = "VM4_RG"
  location = "Central US"
}

resource "azurerm_virtual_network" "taskVnet" {
  name = "Vm4_Vnet"
  address_space = [
    "10.0.0.0/16"]
  location = azurerm_resource_group.taskRG.location
  resource_group_name = azurerm_resource_group.taskRG.name
}

resource "azurerm_subnet" "test" {
  name                 = "VM4_sub"
  resource_group_name  = azurerm_resource_group.taskRG.name
  virtual_network_name = azurerm_virtual_network.taskVnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "taskPIP" {
  name                = "VM4-PIP"
  location            = azurerm_resource_group.taskRG.location
  resource_group_name = azurerm_resource_group.taskRG.name

  allocation_method = "Static"
  sku               = "Standard"
}
resource "azurerm_network_security_group" "taskNSG" {
  name                = "VM4-NSG"
  location            = azurerm_resource_group.taskRG.location
  resource_group_name = azurerm_resource_group.taskRG.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"

    source_port_range          = "*"
    destination_port_range     = "22"

    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowHTTP8080"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"

    source_port_range          = "*"
    destination_port_range     = "8080"

    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "taskNIC" {
  name                = "VM4-NIC"
  location            = azurerm_resource_group.taskRG.location
  resource_group_name = azurerm_resource_group.taskRG.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.test.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.taskPIP.id
  }
}

resource "azurerm_network_interface_security_group_association" "taskAssoc" {
  network_interface_id      = azurerm_network_interface.taskNIC.id
  network_security_group_id = azurerm_network_security_group.taskNSG.id
}

data "azurerm_ssh_public_key" "sshkey" {
  name                = "newKey"
  resource_group_name = "vinay"
}

resource "azurerm_linux_virtual_machine" "taskVM" {
  name                = "VM4"
  resource_group_name = azurerm_resource_group.taskRG.name
  location            = azurerm_resource_group.taskRG.location
  size                = "Standard_D2s_v3"

  admin_username = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.taskNIC.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = data.azurerm_ssh_public_key.sshkey.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku        = "server"
    version    = "latest"
  }

  disable_password_authentication = true
}


output "public_ip" {
  value = azurerm_public_ip.taskPIP.ip_address
}

output "private_ip" {
  value = azurerm_network_interface.taskNIC.private_ip_address
}

resource "local_file" "ansible_inventory" {
  filename = "/home/azureuser/task/CICD_Ansible_Terraform_Azure/ansible/playbooks/inventory.ini"

  content = <<EOF
[VM]
VM4 ansible_host=${azurerm_public_ip.taskPIP.ip_address} ansible_user=azureuser ansible_private_key_file=/home/azureuser/.ssh/newKey.pem
EOF
}
