#Azure
provider "azurerm" {
  features {}
  skip_provider_registration = true
  subscription_id = "c064671c-8f74-4fec-b088-b53c568245eb"
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-network2"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.prefix}-ip"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-nic"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
    private_ip_address            = "10.0.2.11"
  }
}

resource "azurerm_network_security_group" "NSG_SSH" {
  name                = "nsg-1-allowinbound-tcp"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow_Inbound_TCP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface_security_group_association" "add" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.NSG_SSH.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "${var.prefix}-vm"
  resource_group_name   = data.azurerm_resource_group.rg.name
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.ssh_username
  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = var.ssh_username
    public_key = var.ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  custom_data = base64encode(templatefile("${path.module}/userdata.tpl", {
    ssh_user = var.ssh_username
    ssh_key = var.ssh_key
  }))
}

#ESXI

provider "esxi" {
  esxi_hostname      = var.esxi_hostname
  esxi_hostport      = var.esxi_hostport
  esxi_hostssl       = var.esxi_hostssl
  esxi_username      = var.esxi_username
  esxi_password      = var.esxi_password
}

data "template_file" "Default" {
  template = file("userdata.tpl")
  vars = {
    ssh_user = var.ssh_username
    ssh_key = var.ssh_key
  }
}

resource "esxi_guest" "servers" {
  guest_name = "vm1"
  disk_store = "Local_Storage"  
  
  memsize  = "2048"
  numvcpus = "2"
  power    = "on"
  guestos = "Ubuntu"
  ovf_source        = var.ovf_file

  network_interfaces {
    virtual_network = "VM Network" 
  }
  guestinfo = {
    "userdata.encoding" = "gzip+base64"
    "userdata"          = base64gzip(data.template_file.Default.rendered)
    }
}

resource "local_file" "outputs" {
  content = <<-EOT
    [servers]
    ${esxi_guest.servers.ip_address}
    ${azurerm_public_ip.public_ip.ip_address}

    [servers:vars]
    ansible_ssh_user= ${var.ssh_username}
    ansible_ssh_private_key_file=/home/gebruiker/id_ed25519
    become_passwd=
    ansible_ssh_common_args='-o StrictHostKeyChecking=no'
  EOT
  filename = "${path.module}/ansible/inventory.ini"
}
