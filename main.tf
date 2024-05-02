variable "project_name" {
  type    = string
  default = "devops"
}

variable "admin_username" {
  type    = string
  default = "adminuser"
}

variable "admin_password" {
  type    = string
  default = "YourPassword123!"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "setup" {
  name     = "${var.project_name}-rg"
  location = "West Europe"
}

resource "azurerm_virtual_network" "network" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.setup.location
  resource_group_name = azurerm_resource_group.setup.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.project_name}-subnet"
  resource_group_name  = azurerm_resource_group.setup.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.project_name}-public-ip"
  location            = azurerm_resource_group.setup.location
  resource_group_name = azurerm_resource_group.setup.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "network_interface" {
  name                = "${var.project_name}-nic"
  location            = azurerm_resource_group.setup.location
  resource_group_name = azurerm_resource_group.setup.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "virtual_machine" {
  name                            = "${var.project_name}-vm"
  location                        = azurerm_resource_group.setup.location
  resource_group_name             = azurerm_resource_group.setup.name
  network_interface_ids           = [azurerm_network_interface.network_interface.id]
  size                            = "Standard_DS1_v2"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

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
}

data "azurerm_public_ip" "public_ip" {
  name                = azurerm_public_ip.public_ip.name
  resource_group_name = azurerm_linux_virtual_machine.virtual_machine.resource_group_name
}



resource "null_resource" "install_figlet" {
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = var.admin_username
      host     = data.azurerm_public_ip.public_ip.ip_address
      password = var.admin_password
      port     = 22
    }
    inline = [
      "mkdir test",
    ]
  }

  depends_on = [azurerm_linux_virtual_machine.virtual_machine, azurerm_public_ip.public_ip]
}

output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
}
