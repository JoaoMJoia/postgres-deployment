# Fetch subnet id
data "azurerm_subnet" "publicsubnet" {
  name                 = var.subnetname
  virtual_network_name = var.vnet_name
  resource_group_name  = var.rg_name
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
    network_security_group_id = var.custom_security_group_name == "" ? azurerm_network_security_group.mynsg[0].id : var.custom_security_group_name
}


locals {
  DBUSEREPAS="${var.db_user == ""  ? "enterprisedb" : var.db_user}"
  DBPASS="${var.db_password == "" ? "postgres" : var.db_password}"
  CLUSTER_NAME="${var.cluster_name == "" ? "epas12" : var.cluster_name}"
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
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_private_key_path)}' '${path.module}/utilities/scripts/installepas12.yml' --extra-vars='USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password}  EPASDBUSER=${local.DBUSEREPAS}' --limit ${self.public_ip_address}"
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
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_private_key_path)}' '${path.module}/utilities/scripts/configuremasterepas12.yml' --extra-vars='ip1=${azurerm_linux_virtual_machine.edb_vm[1].private_ip_address} ip2=${azurerm_linux_virtual_machine.edb_vm[2].private_ip_address} ip3=${azurerm_linux_virtual_machine.edb_vm[0].private_ip_address} REPLICATION_USER_PASSWORD=${var.replication_password}  EPASDBUSER=${local.DBUSEREPAS} REPLICATION_TYPE=${var.replication_type} DBPASSWORD=${local.DBPASS} STORAGE=${var.storage_account_name} CONTAINER=${var.container_name} SUBSCRIPTION=${data.azurerm_subscription.current.subscription_id} RESOURCEGROUP=${var.rg_name}' --limit ${azurerm_linux_virtual_machine.edb_vm[0].public_ip_address}"

}

}

resource "null_resource" "configureslave1" {

depends_on = [null_resource.configuremaster]

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_private_key_path)}' '${path.module}/utilities/scripts/configureslave.yml' --extra-vars='ip1=${azurerm_linux_virtual_machine.edb_vm[0].private_ip_address} ip2=${azurerm_linux_virtual_machine.edb_vm[2].private_ip_address} REPLICATION_USER_PASSWORD=${var.replication_password} REPLICATION_TYPE=${var.replication_type} SLAVE1=${azurerm_linux_virtual_machine.edb_vm[1].public_ip_address} SLAVE2=${azurerm_linux_virtual_machine.edb_vm[2].public_ip_address} MASTER=${azurerm_linux_virtual_machine.edb_vm[0].public_ip_address} STORAGE=${var.storage_account_name} CONTAINER=${var.container_name} SUBSCRIPTION=${data.azurerm_subscription.current.subscription_id} RESOURCEGROUP=${var.rg_name}' --limit ${azurerm_linux_virtual_machine.edb_vm[1].public_ip_address},${azurerm_linux_virtual_machine.edb_vm[0].public_ip_address}"

}

}

resource "null_resource" "configureslave2" {

depends_on = [null_resource.configuremaster]

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_private_key_path)}' '${path.module}/utilities/scripts/configureslave.yml' --extra-vars='ip1=${azurerm_linux_virtual_machine.edb_vm[0].private_ip_address} ip2=${azurerm_linux_virtual_machine.edb_vm[1].private_ip_address} REPLICATION_USER_PASSWORD=${var.replication_password} REPLICATION_TYPE=${var.replication_type} SLAVE2=${azurerm_linux_virtual_machine.edb_vm[2].public_ip_address} SLAVE1=${azurerm_linux_virtual_machine.edb_vm[1].public_ip_address} MASTER=${azurerm_linux_virtual_machine.edb_vm[0].public_ip_address} STORAGE=${var.storage_account_name} CONTAINER=${var.container_name} SUBSCRIPTION=${data.azurerm_subscription.current.subscription_id} RESOURCEGROUP=${var.rg_name}' --limit ${azurerm_linux_virtual_machine.edb_vm[2].public_ip_address},${azurerm_linux_virtual_machine.edb_vm[0].public_ip_address}"

}

}


resource "null_resource" "efm_setup" {

provisioner "local-exec" {

   command = "sleep 30"
}

depends_on = [
        null_resource.configuremaster,
        null_resource.configureslave2,
        null_resource.configureslave1,
        azurerm_linux_virtual_machine.edb_vm[0],
        azurerm_linux_virtual_machine.edb_vm[1],
        azurerm_linux_virtual_machine.edb_vm[2]
]
provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_private_key_path)}' ${path.module}/utilities/scripts/efm.yml --extra-vars='ip1=${azurerm_linux_virtual_machine.edb_vm[0].private_ip_address} ip2=${azurerm_linux_virtual_machine.edb_vm[1].private_ip_address} ip3=${azurerm_linux_virtual_machine.edb_vm[2].private_ip_address} EFM_USER_PASSWORD=${var.efm_role_password} MASTER=${azurerm_linux_virtual_machine.edb_vm[0].public_ip_address} RG_NAME=${var.rg_name} NOTIFICATION_EMAIL=${var.notification_email_address} DBUSER=${local.DBUSEREPAS}   SLAVE2=${azurerm_linux_virtual_machine.edb_vm[2].public_ip_address} SLAVE1=${azurerm_linux_virtual_machine.edb_vm[1].public_ip_address}' --limit ${azurerm_linux_virtual_machine.edb_vm[0].public_ip_address},${azurerm_linux_virtual_machine.edb_vm[1].public_ip_address},${azurerm_linux_virtual_machine.edb_vm[2].public_ip_address}"

}

}

## PEM Server Creation Start Here #####

resource "azurerm_public_ip" "pem_ip" {
    name                         = "PEMPublicIP"
    location                     = var.region
    resource_group_name          = var.rg_name
    allocation_method            = "Dynamic"

}


resource "azurerm_network_interface" "pemnic" {
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
resource "azurerm_network_security_group" "mynsgpem" {
    count =  var.custom_security_group_name_pem == "" ? "1" : "0"
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
resource "azurerm_network_interface_security_group_association" "mypemassociation" {
    network_interface_id      = azurerm_network_interface.pemnic.id
    network_security_group_id = var.custom_security_group_name_pem == "" ? azurerm_network_security_group.mynsgpem[0].id : var.custom_security_group_name_pem
}



resource "azurerm_linux_virtual_machine" "EDB_Pem_Server" {
  name                            = "Pem-server"
  resource_group_name             = var.rg_name
  location                        = var.region
  size                            = var.instance_size_pem
  admin_username                  = "centos"
  network_interface_ids = [azurerm_network_interface.pemnic.id]

  admin_ssh_key {
    username = "centos"
    public_key = file("${var.ssh_keypair_path}")
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
    command = "echo '${azurerm_linux_virtual_machine.EDB_Pem_Server.public_ip_address} ansible_ssh_private_key_file=${var.ssh_private_key_path_pem}' >> ${path.module}/utilities/scripts/hosts"
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
      private_key = file(var.ssh_private_key_path_pem)
    }
  }

provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_private_key_path_pem)}' '${path.module}/utilities/scripts/pemserver.yml' --extra-vars='USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} PEM_IP=${azurerm_linux_virtual_machine.EDB_Pem_Server.public_ip_address} DB_PASSWORD=${var.db_password_pem}' --limit ${azurerm_linux_virtual_machine.EDB_Pem_Server.public_ip_address}" 
}

depends_on = [
        null_resource.configuremaster,
        null_resource.configureslave2,
        null_resource.configureslave1,
        azurerm_linux_virtual_machine.edb_vm[0],
        azurerm_linux_virtual_machine.edb_vm[1],
        azurerm_linux_virtual_machine.edb_vm[2],
        null_resource.efm_setup
]


}


resource "null_resource" "configurepemagent" {

provisioner "local-exec" {

   command = "sleep 30"
}

depends_on = [
        null_resource.configuremaster,
        null_resource.configureslave2,
        null_resource.configureslave1,
        azurerm_linux_virtual_machine.EDB_Pem_Server,
        azurerm_linux_virtual_machine.edb_vm[0],
        azurerm_linux_virtual_machine.edb_vm[1],
        azurerm_linux_virtual_machine.edb_vm[2],
        null_resource.efm_setup
]

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_private_key_path)}' ${path.module}/utilities/scripts/installpemagent.yml --extra-vars='DBPASSWORD=${local.DBPASS} PEM_IP=${azurerm_linux_virtual_machine.EDB_Pem_Server.public_ip_address} PEM_WEB_PASSWORD=${var.db_password_pem} DBUSER=${local.DBUSEREPAS}' --limit ${azurerm_linux_virtual_machine.edb_vm[0].public_ip_address},${azurerm_linux_virtual_machine.edb_vm[1].public_ip_address},${azurerm_linux_virtual_machine.edb_vm[2].public_ip_address}" 

}

}


resource "azurerm_public_ip" "bart_ip" {
    name                         = "BartPublicIP"
    location                     = var.region
    resource_group_name          = var.rg_name
    allocation_method            = "Dynamic"

}


resource "azurerm_network_interface" "mainbart" {
  name                = "bartnic"
  resource_group_name = var.rg_name
  location            = var.region

  ip_configuration {
    name                          = "bartNicip"
    subnet_id                     =  data.azurerm_subnet.publicsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bart_ip.id

  }
}


resource "azurerm_linux_virtual_machine" "EDB_Bart_Server" {
  name                            = "bart-server"
  resource_group_name             = var.rg_name
  location                        = var.region
  size                            = var.instance_size
  admin_username                  = "centos"
  network_interface_ids = [azurerm_network_interface.mainbart.id]

  admin_ssh_key {
    username = "centos"
    public_key = file("${var.ssh_keypair_bart}")
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
    name              = "bartOsDisk" 
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }


 tags = {
        created_by = "Terraform"
    }

provisioner "local-exec" {
    command = "echo '${azurerm_linux_virtual_machine.EDB_Bart_Server.public_ip_address} ansible_ssh_private_key_file=${var.ssh_private_key_path_bart}' >> ${path.module}/utilities/scripts/hosts"
}


}

resource "azurerm_managed_disk" "data" {
  name                 = "datadisk"
  location             = var.region
  create_option        = "Empty"
  disk_size_gb         = var.size
  resource_group_name  = var.rg_name
  storage_account_type = "Standard_LRS"
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  virtual_machine_id = azurerm_linux_virtual_machine.EDB_Bart_Server.id
  managed_disk_id    = azurerm_managed_disk.data.id
  lun                = 0
  caching            = "None"
}

resource "null_resource" "configurebart" {

provisioner "local-exec" {
    command = "sleep 60" 
}

provisioner "remote-exec" {
    inline = [
     "yum info python"
]
connection {
      host = azurerm_linux_virtual_machine.EDB_Bart_Server.public_ip_address 
      type = "ssh"
      user = "centos"
      private_key = file(var.ssh_private_key_path_bart)
    }
  }

provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_private_key_path_bart)}' '${path.module}/utilities/scripts/bartserver.yml' --extra-vars='USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} BART_IP=${azurerm_linux_virtual_machine.EDB_Bart_Server.public_ip_address} DB_IP=${azurerm_linux_virtual_machine.edb_vm[0].public_ip_address} DB_ENGINE=eaps12 DB_PASSWORD=${local.DBPASS} DB_USER=${local.DBUSEREPAS} RETENTION_PERIOD=\"${var.retention_period}\"'" 
}


depends_on = [
        null_resource.configuremaster,
        null_resource.configureslave2,
        null_resource.configureslave1,
        azurerm_linux_virtual_machine.EDB_Pem_Server,
        azurerm_linux_virtual_machine.edb_vm[0],
        azurerm_linux_virtual_machine.edb_vm[1],
        azurerm_linux_virtual_machine.edb_vm[2],
        null_resource.efm_setup,
        null_resource.configurepemagent
]


}

data "azurerm_subscription" "current" {
}

resource "azurerm_role_assignment" "mybartroleassginment" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = lookup(azurerm_linux_virtual_machine.EDB_Bart_Server.identity[0], "principal_id")

  depends_on = [
        null_resource.configuremaster,
        null_resource.configureslave2,
        null_resource.configureslave1,
        azurerm_linux_virtual_machine.EDB_Pem_Server,
        azurerm_linux_virtual_machine.edb_vm[0],
        azurerm_linux_virtual_machine.edb_vm[1],
        azurerm_linux_virtual_machine.edb_vm[2],
        null_resource.efm_setup,
        null_resource.configurepemagent,
        azurerm_linux_virtual_machine.EDB_Bart_Server

        
] 

}



resource "null_resource" "remotehostfile" {

provisioner "local-exec" {

   command = "rm -rf  ${path.module}/utilities/scripts/hosts"
}

depends_on = [
        null_resource.configuremaster,
        null_resource.configureslave2,
        null_resource.configureslave1,
        azurerm_linux_virtual_machine.EDB_Pem_Server,
        null_resource.configurepemagent,
        azurerm_linux_virtual_machine.edb_vm,
        azurerm_linux_virtual_machine.EDB_Bart_Server,
        azurerm_role_assignment.mybartroleassginment
]
}

