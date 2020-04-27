###### Mandatory Fields in this config file #####
### region_name
### instance_type
### ssh_keypair   
### ssh_key_path
### vpc_id
### subnet_id
### EDB_yumrepo_username
### EDB_yumrepo_password
### db_password 
#############################################

### Optional Field in this config file
### custom_security_group_id
### retention_period
###########################################


provider "azurerm" {
  version = "2.5"
  features {}
}

module "edb-bart-server" {
  # The source module to be used.

  source = "./EDB_BART_Server"
  
  # Enter EDB yum repository credentials for any EDB tools.

  EDB_yumrepo_username = ""

  # Enter EDB yum repository credentials for any EDB tools.

  EDB_yumrepo_password = ""

  # Provide region name where resource going to create like East US.

  region = ""

  # Provide Virtual network name.

   vnet_name = ""

  # Enter public subnet name of virtual network 

  subnetname = ""


  # Provide resource group name

  rg_name = ""

  # Enter Azure VM type like  Standard_D2s_v3, Standard_B1ms  etc.
 
  instance_size = ""

  # Provide path of ssh public file. This path should be absolute path. 
  # eg ssh_key_path = "/Users/edb/Documents/azurepubkey"

  ssh_key_path = "" 

  # Provide path of ssh private file from your local system. 
  # eg. ssh_private_key_path = "/Users/edb/Documents/abc.pem"

  ssh_private_key_path = ""

  # Enter DB user name. This is Database username you have given while creating 3 node DB cluster 
  # eg. db_user = "postgres" 

   db_user = ""

  # Enter DB password. This is database password you have set while creating 3 node DB cluster. Provide password in pain text. 
  

  db_password = ""

  # Specify the retention policy for the backup. This determines when an
  #  active backup should be marked as obsolete. You can specify the retention policy either in terms of number
  #  of backup or in terms of duration (days, weeks, or months). eg 3 MONTHS or 7 DAYS or 1 WEEK
  # Leave it blank if you dont want to specify retention period.
 
  retention_period = ""

  # Provide size of volume where bart server will take back up. This is just a number. For example size = 10 
  # will creare and attach volume of size 10GB

  size =  10



}  

output "Bart_SERVER_IP" {
  value = "${module.edb-bart-server.Bart-IP}"
}


