data "terraform_remote_state" "DB_CLUSTER" {
  backend = "local"

  config = {
    path = "../${path.root}/DB_Cluster/terraform.tfstate"
  }
}

data "terraform_remote_state" "PEM_SERVER" {
  backend = "local"

  config = {
    path = "../${path.root}/PEM_Server/terraform.tfstate"
  }
}


data "azurerm_subnet" "publicsubnet" {
  name                 = var.subnetname
  virtual_network_name = var.vnet_name
  resource_group_name  = data.terraform_remote_state.DB_CLUSTER.outputs.RG_NAME
}

resource "azurerm_public_ip" "mypublicip1" {
    name                         = "Standby3PublicIP"
    location                     = var.region
    resource_group_name          = data.terraform_remote_state.DB_CLUSTER.outputs.RG_NAME
    allocation_method            = "Dynamic"

}


resource "azurerm_network_interface" "main" {
  name                = "standby3nic"
  resource_group_name = data.terraform_remote_state.DB_CLUSTER.outputs.RG_NAME
  location            = var.region

  ip_configuration {
    name                          = "standby3Nicip"
    subnet_id                     =  data.azurerm_subnet.publicsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          =  azurerm_public_ip.mypublicip1.id

  }
}


# Create Network Security Group and rule
resource "azurerm_network_security_group" "mynsg" {
    count = var.custom_security_group_name == "" ? "1" : "0"
    name                = "edbnsgnew"
    location            = var.region
    resource_group_name = data.terraform_remote_state.DB_CLUSTER.outputs.RG_NAME
    
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
    network_interface_id      = azurerm_network_interface.main.id
    network_security_group_id = var.custom_security_group_name == "" ? azurerm_network_security_group.mynsg[0].id : var.custom_security_group_name
}



resource "azurerm_linux_virtual_machine" "EDB_Expand_DBCluster" {
  name                            = "${local.Cluster_name}-standby3"
  resource_group_name             = data.terraform_remote_state.DB_CLUSTER.outputs.RG_NAME
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
    name              = "OsDiskstandby3" 
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

 tags = {
        created_by = "Terraform"
    }


provisioner "local-exec" {
    command = "sleep 60" 
}

provisioner "local-exec" {
    command = "echo '${azurerm_linux_virtual_machine.EDB_Expand_DBCluster.public_ip_address} ansible_ssh_private_key_file=${data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path}' > ${path.module}/utilities/scripts/hosts"
}

provisioner "remote-exec" {
    inline = [
     "yum info python"
]
connection {
      host = azurerm_linux_virtual_machine.EDB_Expand_DBCluster.public_ip_address 
      type = "ssh"
      user = "centos"
      private_key = file(data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path)
    }
  }

provisioner "local-exec" {
      command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path)}' '${path.module}/utilities/scripts/install${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE}.yml' --extra-vars='USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS}' --limit ${azurerm_linux_virtual_machine.EDB_Expand_DBCluster.public_ip_address}" 
}


}


data "azurerm_subscription" "current" {
}

resource "azurerm_role_assignment" "myroleassginment" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = lookup(azurerm_linux_virtual_machine.EDB_Expand_DBCluster.identity[0], "principal_id")

  depends_on = [
        azurerm_linux_virtual_machine.EDB_Expand_DBCluster,
]

}

locals {
  DBUSERPG="${var.db_user == "" || data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE == regexall("${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE}", "pg10 pg11 pg12") ? "postgres" : var.db_user}"
  DBUSEREPAS="${var.db_user == "" || data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE == regexall("${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE}", "eaps10 epas11 epas12") ? "enterprisedb" : var.db_user}"
  DBPASS="${var.db_password == "" ? "postgres" : var.db_password}"
  Cluster_name="${data.terraform_remote_state.DB_CLUSTER.outputs.CLUSTER_NAME == "" ? data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE : data.terraform_remote_state.DB_CLUSTER.outputs.CLUSTER_NAME}"
}
######################################

## Addition of new node in replicaset begins here

#####################################


resource "null_resource" "configure_streaming_replication" {
  # Define the trigger condition to run the resource block
  triggers = {
    cluster_instance_ids = "${azurerm_linux_virtual_machine.EDB_Expand_DBCluster.id}"
  }

  depends_on = [azurerm_linux_virtual_machine.EDB_Expand_DBCluster]

  provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.DB_CLUSTER.outputs.Master-PublicIP} ansible_ssh_private_key_file=${data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path}' >> ${path.module}/utilities/scripts/hosts"
} 

provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.DB_CLUSTER.outputs.Standby1-PublicIP} ansible_ssh_private_key_file=${data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path}' >> ${path.module}/utilities/scripts/hosts"
}

provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.DB_CLUSTER.outputs.Standby2-PublicIP} ansible_ssh_private_key_file=${data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path}' >> ${path.module}/utilities/scripts/hosts"
}



provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path)}' '${path.module}/utilities/scripts/configureslave.yml' --extra-vars='ip1=${data.terraform_remote_state.DB_CLUSTER.outputs.Master-PrivateIP} ip2=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby1-PrivateIP} ip3=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby2-PrivateIP} IPPRIVATE=${azurerm_linux_virtual_machine.EDB_Expand_DBCluster.private_ip_address} REPLICATION_USER_PASSWORD=${var.replication_password} DB_ENGINE=${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE} REPLICATION_TYPE=${var.replication_type} MASTER=${data.terraform_remote_state.DB_CLUSTER.outputs.Master-PublicIP} SLAVE1=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby1-PublicIP} SLAVE2=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby2-PublicIP} NEWSLAVE=${azurerm_linux_virtual_machine.EDB_Expand_DBCluster.public_ip_address} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS} STORAGE=${data.terraform_remote_state.DB_CLUSTER.outputs.STORAGE_ACCOUNT_NAME} CONTAINER=${data.terraform_remote_state.DB_CLUSTER.outputs.Container_Name} SUBSCRIPTION=${data.azurerm_subscription.current.subscription_id} RESOURCEGROUP=${data.terraform_remote_state.DB_CLUSTER.outputs.RG_NAME}'" 

}

}

resource "null_resource" "configureefm" {

triggers = {
    cluster_instance_ids = "${azurerm_linux_virtual_machine.EDB_Expand_DBCluster.id}"
  }

depends_on = [null_resource.configure_streaming_replication]

provisioner "local-exec" {

   command = "sleep 30"
}

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path)}' ${path.module}/utilities/scripts/configureefm.yml --extra-vars='ip1=${data.terraform_remote_state.DB_CLUSTER.outputs.Master-PrivateIP} ip2=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby1-PrivateIP} ip3=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby2-PrivateIP} EFM_USER_PASSWORD=${var.efm_role_password} MASTER_PUB_IP=${data.terraform_remote_state.DB_CLUSTER.outputs.Master-PublicIP} RG_NAME=${data.terraform_remote_state.DB_CLUSTER.outputs.RG_NAME} selfip=${azurerm_linux_virtual_machine.EDB_Expand_DBCluster.private_ip_address} USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} DB_ENGINE=${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE} NOTIFICATION_EMAIL=${var.notification_email_address} IPPRIVATE=${azurerm_linux_virtual_machine.EDB_Expand_DBCluster.private_ip_address} SLAVE1=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby1-PublicIP} SLAVE2=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby2-PublicIP}  NEWSLAVE=${azurerm_linux_virtual_machine.EDB_Expand_DBCluster.public_ip_address} MASTER=${data.terraform_remote_state.DB_CLUSTER.outputs.Master-PublicIP} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS}' --limit ${azurerm_linux_virtual_machine.EDB_Expand_DBCluster.public_ip_address},${data.terraform_remote_state.DB_CLUSTER.outputs.Master-PublicIP},${data.terraform_remote_state.DB_CLUSTER.outputs.Standby2-PublicIP},${data.terraform_remote_state.DB_CLUSTER.outputs.Standby1-PublicIP}"

}

}


resource "null_resource" "configurepemagent" {

triggers = { 
    path = "${path.root}/PEM_Server_AWS"
  }

depends_on = [ 
   azurerm_linux_virtual_machine.EDB_Expand_DBCluster,
   null_resource.configureefm
]

provisioner "local-exec" {

   command = "sleep 30"
}

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path)}' ${path.module}/utilities/scripts/installpemagent.yml --extra-vars='DBPASSWORD=${local.DBPASS} PEM_IP=${data.terraform_remote_state.PEM_SERVER.outputs.PEM_SERVER_IP} PEM_WEB_PASSWORD=${var.pem_web_ui_password} USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} DB_ENGINE=${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS}' --limit ${azurerm_linux_virtual_machine.EDB_Expand_DBCluster.public_ip_address}"

}

}



resource "null_resource" "removehostfile" {

provisioner "local-exec" {
  command = "rm -rf ${path.module}/utilities/scripts/hosts"
}

depends_on = [
      null_resource.configurepemagent,
      null_resource.configureefm,
      null_resource.configure_streaming_replication,
      azurerm_linux_virtual_machine.EDB_Expand_DBCluster
]
}

