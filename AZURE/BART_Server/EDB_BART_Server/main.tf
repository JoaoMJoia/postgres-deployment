data "terraform_remote_state" "SR" {
  backend = "local"

  config = {
    path = "../${path.root}/DB_Cluster/terraform.tfstate"
  }
}

# Fetch subnet id
data "azurerm_subnet" "publicsubnet" {
  name                 = var.subnetname
  virtual_network_name = var.vnet_name
  resource_group_name  = var.rg_name
}

resource "azurerm_public_ip" "bart_ip" {
    name                         = "BartPublicIP"
    location                     = var.region
    resource_group_name          = var.rg_name
    allocation_method            = "Dynamic"

}


resource "azurerm_network_interface" "main" {
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
    name              = "bartOsDisk" 
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }


 tags = {
        created_by = "Terraform"
    }

provisioner "local-exec" {
    command = "echo '${azurerm_linux_virtual_machine.EDB_Bart_Server.public_ip_address} ansible_ssh_private_key_file=${var.ssh_private_key_path}' > ${path.module}/utilities/scripts/hosts"
}

provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.SR.outputs.Master-PublicIP} ansible_ssh_private_key_file=${data.terraform_remote_state.SR.outputs.Key-Pair-Path}' >> ${path.module}/utilities/scripts/hosts"
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
      private_key = file(var.ssh_private_key_path)
    }
  }

provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_private_key_path)}' '${path.module}/utilities/scripts/bartserver.yml' --extra-vars='USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} BART_IP=${azurerm_linux_virtual_machine.EDB_Bart_Server.public_ip_address} DB_IP=${data.terraform_remote_state.SR.outputs.Master-PublicIP} DB_ENGINE=${data.terraform_remote_state.SR.outputs.DBENGINE} DB_PASSWORD=${var.db_password} DB_USER=${var.db_user} RETENTION_PERIOD=\"${var.retention_period}\"'" 
}


}


data "azurerm_subscription" "current" {
}

resource "azurerm_role_assignment" "mybartroleassginment" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = lookup(azurerm_linux_virtual_machine.EDB_Bart_Server.identity[0], "principal_id")

  depends_on = [ 
        azurerm_linux_virtual_machine.EDB_Bart_Server, 
]        

}



resource "null_resource" "removehostfile" {

provisioner "local-exec" {
  command = "rm -rf ${path.module}/utilities/scripts/hosts"
}

depends_on = [
    azurerm_linux_virtual_machine.EDB_Bart_Server,
    null_resource.configurebart,
    azurerm_virtual_machine_data_disk_attachment.data,
    azurerm_managed_disk.data,
    azurerm_role_assignment.mybartroleassginment

]
}

