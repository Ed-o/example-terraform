# main.tf

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.project_name
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "web" {
  name                 = "web-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "lb" {
  name                = "${var.project_name}-lb-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "main" {
  name                = "${var.project_name}-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

resource "azurerm_network_interface" "web" {
  count               = 2
  name                = "web-nic-${count.index}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    load_balancer_backend_address_pools_ids = [
      azurerm_lb_backend_address_pool.main.id
    ]
  }
}

resource "azurerm_linux_virtual_machine" "web" {
  count               = 2
  name                = "web-vm-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.web[count.index].id
  ]
  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.ssh_public_key)
  }
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

resource "azurerm_mysql_server" "main" {
  name                = "${var.project_name}-mysql"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  administrator_login          = var.mysql_admin_username
  administrator_login_password = var.mysql_admin_password
  sku_name             = "B_Gen5_1"
  storage_mb           = 5120
  version              = "5.7"
  auto_grow_enabled    = true
  backup_retention_days = 7
  geo_redundant_backup = "Disabled"
}

# Backend Pool for Load Balancer
resource "azurerm_lb_backend_address_pool" "main" {
  name                = "${var.project_name}-be-pool"
  loadbalancer_id     = azurerm_lb.main.id
  resource_group_name = azurerm_resource_group.main.name
}

