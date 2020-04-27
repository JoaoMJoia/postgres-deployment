###### Mandatory Fields in this config file #####
### region
### vnet_name
### subnetname
### rg_name
### instance_size
### ssh_keypair   
### ssh_key_path
### subnetname
### EDB_yumrepo_username
### EDB_yumrepo_password
### db_password 
### ssh_private_key_path
#############################################

### Optional Field in this config file
### custom_security_group_name

###########################################


provider "azurerm" {
   version = "2.5"
   features {}
}

module "edb-pem-server" {
  # The source module to be used.

  source = "./EDB_PEM_Server"
  
  # Enter EDB yum repository credentials for any EDB tools.

  EDB_yumrepo_username = ""

  # Enter EDB yum repository credentials for any EDB tools.

  EDB_yumrepo_password = ""

  # Provide region name where resource going to create.
  # Eg. region = "East US"

  region = ""

  # Enter this mandatory field which is Virtual network name.
  # vnet_name = "testing-vnet"

  vnet_name = ""

  # Enter public subnet name in virtual network. 
  # Eg. subnetname = "default"

  subnetname = ""

  # Provide resource group name created in Azure. 
  # Eg. rg_name = "testing-cds"

  rg_name = ""

  # Enter Azure Instance type like Standard_D2s_v3, Standard_B1ms  etc.
  # Eg. instance_size = "Standard_B1ms"

  instance_size = ""
 
  # Enter Azure  Network Security Group name. If left blank new security group will create and attached to newly created instance ...
  # Eg. custom_security_group_name = ""
 
  custom_security_group_name = ""

  # Provide ssh private key path. This is private key file path for ssh connectivity.
  # ssh_private_key_path = "/Users/edb/Documents/abc.pem"

  ssh_private_key_path = ""

  # Provide path of ssh public key file. This file contains public key for ssh connectivity.
  # Eg. ssh_key_path = "/Users/edb/Documents/azurepubkey"

  ssh_key_path = ""

  # Enter DB password. This is local DB password of PEM monitoring server.
  # Eg. db_password = "adminedb"

  db_password = ""

}  

output "PEM_SERVER_IP" {
  value = "${module.edb-pem-server.Pem-IP}"
}


