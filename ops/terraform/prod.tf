# Vars

variable "mysql_admin_username" {
  type = string
}

variable "mysql_admin_password" {
  type = string
}

variable "mysql_db_name" {
  type = string
}

variable "admin_user" {
  type = string
}

variable "az_region" {
  type = string
}

# Outputs

output "vm_instance_ip_addr" {
  value = azurerm_linux_virtual_machine.polling_app_vm.public_ip_address
}


output "db_instance_fqdn" {
  value = azurerm_mysql_server.polling_app_db.fqdn
}

# Definitions

provider "azurerm" {
  version = "=2.15.0"
  features {}
}

resource "azurerm_resource_group" "polling_app" {
  name     = "prod_polling_app"
  location = var.az_region
}

resource "azurerm_virtual_network" "polling_app_virt_net" {
  name                = "prod_polling_app_virt_net"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.polling_app.location
  resource_group_name = azurerm_resource_group.polling_app.name
}

resource "azurerm_subnet" "polling_app_virt_net_subnet" {
  name                 = "prod_polling_app_virt_net_subnet"
  resource_group_name  = azurerm_resource_group.polling_app.name
  virtual_network_name = azurerm_virtual_network.polling_app_virt_net.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "polling_app_public_ip" {
  name                = "prod_polling_app_public_ip"
  location            = azurerm_resource_group.polling_app.location
  resource_group_name = azurerm_resource_group.polling_app.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "polling_app_network_interface" {
  name                = "prod_polling_app_network_interface"
  location            = azurerm_resource_group.polling_app.location
  resource_group_name = azurerm_resource_group.polling_app.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.polling_app_virt_net_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.polling_app_public_ip.id
  }
}

resource "azurerm_network_security_group" "polling_app_security_group" {
  name                = "prod_polling_app_nsg"
  location            = azurerm_resource_group.polling_app.location
  resource_group_name = azurerm_resource_group.polling_app.name

  security_rule {
    name                       = "allow_ssh"
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
    name                       = "allow_8080_in"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_vnet"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    source_port_range          = "*"
    destination_port_range     = "*"
  }

  security_rule {
    name                       = "allow_load_balancer"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
  }

  security_rule {
    name                       = "allow_3306_out"
    priority                   = 500
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "polling_app_nsg_association" {
  network_interface_id      = azurerm_network_interface.polling_app_network_interface.id
  network_security_group_id = azurerm_network_security_group.polling_app_security_group.id
}

resource "azurerm_linux_virtual_machine" "polling_app_vm" {
  name                = "prod-polling-app-vm"
  resource_group_name = azurerm_resource_group.polling_app.name
  location            = azurerm_resource_group.polling_app.location
  size                = "Standard_B1ls"
  admin_username      = var.admin_user
  network_interface_ids = [
    azurerm_network_interface.polling_app_network_interface.id,
  ]

  admin_ssh_key {
    username   = var.admin_user
    public_key = file("~/.ssh/azure/id_rsa.pub")
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

# MySql

resource "azurerm_mysql_server" "polling_app_db" {
  name                = "prod-polling-app-db-v1"
  location            = azurerm_resource_group.polling_app.location
  resource_group_name = azurerm_resource_group.polling_app.name

  administrator_login          = var.mysql_admin_username
  administrator_login_password = var.mysql_admin_password

  sku_name   = "B_Gen5_1"
  storage_mb = 5120
  version    = "5.7"

  auto_grow_enabled                 = false
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = false
  infrastructure_encryption_enabled = true
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"
}

resource "azurerm_mysql_firewall_rule" "polling_app_db_firewall" {
  name                = "prod_polling_app_firewall"
  resource_group_name = azurerm_resource_group.polling_app.name
  server_name         = azurerm_mysql_server.polling_app_db.name
  start_ip_address    = azurerm_linux_virtual_machine.polling_app_vm.public_ip_address
  end_ip_address      = azurerm_linux_virtual_machine.polling_app_vm.public_ip_address
}

resource "local_file" "ansible_env_vars" {
  sensitive_content = <<-E0T
    ---
    DB_HOST: ${azurerm_mysql_server.polling_app_db.fqdn}
    DB_PORT: 3306
    DB_NAME: ${var.mysql_db_name}
    DB_USER: ${azurerm_mysql_server.polling_app_db.administrator_login}@${azurerm_mysql_server.polling_app_db.name}
    DB_PASS: ${var.mysql_admin_password}
    DB_TYPE: mysql
    ENDPOINT_ADDRESS: ${azurerm_mysql_server.polling_app_db.name}
    PORT: 3306
    MASTER_USERNAME: ${azurerm_mysql_server.polling_app_db.administrator_login}@${azurerm_mysql_server.polling_app_db.name}
    MASTER_PASSWORD: ${var.mysql_admin_password}
    E0T
  filename          = "${path.module}/../ansible/roles/webserver/vars/env.yaml"
  file_permission   = "0444"
}

resource "local_file" "ansible_dynamic_inventory" {
  content         = <<-E0T
    ---
    plugin: azure_rm
    include_vm_resource_groups:
      - ${azurerm_resource_group.polling_app.name}
    auth_source: cli
    conditional_groups:
      webserver: true  # add all to webserver group
    E0T
  filename        = "${path.module}/../ansible/inventory.azure_rm.yaml"
  file_permission = "0444"
}
