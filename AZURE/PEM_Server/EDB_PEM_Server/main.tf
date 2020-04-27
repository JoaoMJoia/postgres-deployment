# Fetch subnet id
data "azurerm_subnet" "publicsubnet" {
  name                 = var.subnetname
  virtual_network_name = var.vnet_name
  resource_group_name  = var.rg_name
}

data "azurerm_network_security_group" "customnsg" {
  name                = var.custom_security_group_name
  resource_group_name = var.rg_name
}


resource "azurerm_public_ip" "pem_ip" {
    name                         = "PEMPublicIP"
    location                     = var.region
    resource_group_name          = var.rg_name
    allocation_method            = "Dynamic"

}


resource "azurerm_network_interface" "main" {
  name                = "pemnic"
  resource_group_name = var.rg_name
  location            = var.region

  ip_configuration {
    name                          = "pemNicip"
    subnet_id                     =  data.azurerm_subnet.publicsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pem_ip.id

  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "mynsg" {
    count = var.custom_security_group_name == "" ? "1" : "0"
    name                = "edbpemnsg"
    location            = var.region
    resource_group_name = var.rg_name
    
    security_rule {
        name                       = "SSH"
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
        name                       = "Postgres_DB_Access"
        priority                   = 200
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "5432"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

  security_rule {
        name                       = "Epas_DB_Access"
        priority                   = 300
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "5444"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

 security_rule {
        name                       = "EFM"
        priority                   = 400
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }


    tags = {
        created_by = "Terraform"
    }
}



## Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "myassociation" {
    network_interface_id      = azurerm_network_interface.main.id
    network_security_group_id = var.custom_security_group_name == "" ? azurerm_network_security_group.mynsg[0].id : data.azurerm_network_security_group.customnsg.id
}



resource "azurerm_linux_virtual_machine" "EDB_Pem_Server" {
  name                            = "Pem-server"
  resource_group_name             = var.rg_name
  location                        = var.region
  size                            = var.instance_size
  admin_username                  = "centos"
  network_interface_ids = [azurerm_network_interface.main.id]

  admin_ssh_key {
    username = "centos"
    public_key = file("${var.ssh_key_path}")
  }

  identity {
        type = "SystemAssigned"
    }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "Centos"
    sku       = "7.7"
    version   = "latest"
  }

  os_disk {
    name              = "PemOsDisk" 
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

 tags = {
        created_by = "Terraform"
    }


provisioner "local-exec" {
    command = "echo '${azurerm_linux_virtual_machine.EDB_Pem_Server.public_ip_address} ansible_ssh_private_key_file=${var.ssh_private_key_path}' > ${path.module}/utilities/scripts/hosts"
}

provisioner "local-exec" {
    command = "sleep 60" 
}

provisioner "remote-exec" {
    inline = [
     "yum info python"
]
connection {
      host = azurerm_linux_virtual_machine.EDB_Pem_Server.public_ip_address 
      type = "ssh"
      user = "centos"
      private_key = file(var.ssh_private_key_path)
    }
  }

provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_private_key_path)}' '${path.module}/utilities/scripts/pemserver.yml' --extra-vars='USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} PEM_IP=${azurerm_linux_virtual_machine.EDB_Pem_Server.public_ip_address} DB_PASSWORD=${var.db_password}' --limit ${azurerm_linux_virtual_machine.EDB_Pem_Server.public_ip_address}" 
}

}

resource "null_resource" "removehostfile" {

provisioner "local-exec" {
  command = "rm -rf ${path.module}/utilities/scripts/hosts"
}

depends_on = [
    azurerm_linux_virtual_machine.EDB_Pem_Server
]
}

