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

resource "azurerm_public_ip" "myterraformpublicip1" {
    count = 3
    name                         = "PublicIP${count.index}"
    location                     = var.region
    resource_group_name          = var.rg_name
    allocation_method            = "Dynamic"

}

resource "azurerm_public_ip" "masterpubip" {
    name                         = "MasterPublicIP"
    location                     = var.region
    resource_group_name          = var.rg_name
    allocation_method            = "Static"

}

resource "azurerm_network_interface" "main" {
  count = 3
  name                = "nic${count.index}"
  resource_group_name = var.rg_name
  location            = var.region

  ip_configuration {
    name                          = "Nicip${count.index}"
    subnet_id                     =  data.azurerm_subnet.publicsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = count.index == 0 ? azurerm_public_ip.masterpubip.id : azurerm_public_ip.myterraformpublicip1[count.index].id
    #public_ip_address_id          = element(azurerm_public_ip.myterraformpublicip1.*.id, count.index)

  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "mynsg" {
    count = var.custom_security_group_name == "" ? "1" : "0"
    name                = "edbnsg"
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
        destination_port_range     = "7800-7900"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }


    tags = {
        created_by = "Terraform"
    }
}



## Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "myassociation" {
    count = 3
    network_interface_id      = element(azurerm_network_interface.main.*.id, count.index)
    network_security_group_id = var.custom_security_group_name == "" ? azurerm_network_security_group.mynsg[0].id : data.azurerm_network_security_group.customnsg.id
}


locals {
  DBUSERPG="${var.db_user == "" || var.dbengine == regexall("${var.dbengine}", "pg10 pg11 pg12") ? "postgres" : var.db_user}"
  DBUSEREPAS="${var.db_user == "" || var.dbengine == regexall("${var.dbengine}", "epas10 eaps11 epas12") ? "enterprisedb" : var.db_user}"
  DBPASS="${var.db_password == "" ? "postgres" : var.db_password}"
  CLUSTER_NAME="${var.cluster_name == "" ? var.dbengine : var.cluster_name}"
}

resource "azurerm_linux_virtual_machine" "edb_vm" {
  name                            = count.index == 0 ? "${local.CLUSTER_NAME}-master" : "${local.CLUSTER_NAME}-standby${count.index}"
  count                           = "3"
  resource_group_name             = var.rg_name
  location                        = var.region
  size                            = var.instance_size
  admin_username                  = "centos"
  network_interface_ids = ["${element(azurerm_network_interface.main.*.id, count.index)}"]

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
    name              = "OsDisk${count.index}" 
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

 tags = {
        created_by = "Terraform"
    }

#}


provisioner "local-exec" {
    command = "echo '${self.public_ip_address} ansible_ssh_private_key_file=${var.ssh_private_key_path}' >> ${path.module}/utilities/scripts/hosts"
}

provisioner "local-exec" {
    command = "sleep 60"
}

provisioner "remote-exec" {
    inline = [
     "yum info python"
]
connection {
      host = self.public_ip_address
      type = "ssh"
      user = "centos"
      private_key = file(var.ssh_private_key_path)
    }
  }

provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_private_key_path)}' '${path.module}/utilities/scripts/install${var.dbengine}.yml' --extra-vars='USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS}' --limit ${self.public_ip_address}"
}


}


# Create storage account
resource "azurerm_storage_account" "terraform_storage" {
  name                     = var.storage_account_name
  resource_group_name      = var.rg_name
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind = "Storage"

  network_rules {
    default_action             = "Allow"
    virtual_network_subnet_ids = [data.azurerm_subnet.publicsubnet.id]
  }

}

# Create container
resource "azurerm_storage_container" "mycontainer" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.terraform_storage.name
  container_access_type = "private"
  
}



data "azurerm_subscription" "current" {
}

resource "azurerm_role_assignment" "myroleassginment" {
  count                = 3 
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = lookup(azurerm_linux_virtual_machine.edb_vm[count.index].identity[0], "principal_id")

  depends_on = [ 
        azurerm_linux_virtual_machine.edb_vm, 
        azurerm_storage_container.mycontainer
] 

}



#####################################
## Configuration of streaming replication start here
#####################################


resource "null_resource" "configuremaster" {

depends_on = [azurerm_linux_virtual_machine.edb_vm[0]]



provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_private_key_path)}' '${path.module}/utilities/scripts/configuremaster.yml' --extra-vars='ip1=${azurerm_linux_virtual_machine.edb_vm[1].private_ip_address} ip2=${azurerm_linux_virtual_machine.edb_vm[2].private_ip_address} ip3=${azurerm_linux_virtual_machine.edb_vm[0].private_ip_address} REPLICATION_USER_PASSWORD=${var.replication_password} DB_ENGINE=${var.dbengine} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS} REPLICATION_TYPE=${var.replication_type} DBPASSWORD=${local.DBPASS} STORAGE=${var.storage_account_name} CONTAINER=walfiles SUBSCRIPTION=${data.azurerm_subscription.current.subscription_id} RESOURCEGROUP=${var.rg_name}' --limit ${azurerm_linux_virtual_machine.edb_vm[0].public_ip_address}"

}

}

resource "null_resource" "configureslave1" {

depends_on = [null_resource.configuremaster]

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_private_key_path)}' '${path.module}/utilities/scripts/configureslave.yml' --extra-vars='ip1=${azurerm_linux_virtual_machine.edb_vm[0].private_ip_address} ip2=${azurerm_linux_virtual_machine.edb_vm[2].private_ip_address} REPLICATION_USER_PASSWORD=${var.replication_password} DB_ENGINE=${var.dbengine} REPLICATION_TYPE=${var.replication_type} SLAVE1=${azurerm_linux_virtual_machine.edb_vm[1].public_ip_address} SLAVE2=${azurerm_linux_virtual_machine.edb_vm[2].public_ip_address} MASTER=${azurerm_linux_virtual_machine.edb_vm[0].public_ip_address} STORAGE=${var.storage_account_name} CONTAINER=walfiles SUBSCRIPTION=${data.azurerm_subscription.current.subscription_id} RESOURCEGROUP=${var.rg_name}' --limit ${azurerm_linux_virtual_machine.edb_vm[1].public_ip_address},${azurerm_linux_virtual_machine.edb_vm[0].public_ip_address}"

}

}

resource "null_resource" "configureslave2" {

depends_on = [null_resource.configuremaster]

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_private_key_path)}' '${path.module}/utilities/scripts/configureslave.yml' --extra-vars='ip1=${azurerm_linux_virtual_machine.edb_vm[0].private_ip_address} ip2=${azurerm_linux_virtual_machine.edb_vm[1].private_ip_address} REPLICATION_USER_PASSWORD=${var.replication_password} DB_ENGINE=${var.dbengine} REPLICATION_TYPE=${var.replication_type} SLAVE2=${azurerm_linux_virtual_machine.edb_vm[2].public_ip_address} SLAVE1=${azurerm_linux_virtual_machine.edb_vm[1].public_ip_address} MASTER=${azurerm_linux_virtual_machine.edb_vm[0].public_ip_address} STORAGE=${var.storage_account_name} CONTAINER=walfiles SUBSCRIPTION=${data.azurerm_subscription.current.subscription_id} RESOURCEGROUP=${var.rg_name}' --limit ${azurerm_linux_virtual_machine.edb_vm[2].public_ip_address},${azurerm_linux_virtual_machine.edb_vm[0].public_ip_address}"

}

}


resource "null_resource" "removehostfile" {

provisioner "local-exec" {
  command = "rm -rf ${path.module}/utilities/scripts/hosts"
}

depends_on = [
      null_resource.configureslave2,
      null_resource.configureslave1,
      null_resource.configuremaster,
      azurerm_linux_virtual_machine.edb_vm
]
}



