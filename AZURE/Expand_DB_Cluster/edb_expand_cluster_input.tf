###### Mandatory Fields in this config file #####
### region
### vnet_name
### ssh_key_path
### instance_size
### subnetname
### EDB_yumrepo_username
### EDB_yumrepo_password
### replication_password 
### db_password
### notification_email_address
### efm_role_password
### pem_web_ui_password

#############################################

### Optional Field in this config file
### custom_security_group_name
### replication_type } by default asynchronous
###########################################

### Default User DB credentials##########

## You can change this any time

### For PG10, PG11, PG12
## Username: postgres
## Password: postgres

### For EPAS10, EPAS11, EPAS12
## Username: enterprisedb
## Password: postgres
########################################


provider "azurerm" {
   version = "2.5"
   features {}
}

module "edb-expand-db-cluster" {
  # The source module to be used.
  
  source = "./EDB_ADD_REPLICA"
  
  # Enter EDB yum repository credentials for usage of any EDB tools. 

  EDB_yumrepo_username = ""

  # Enter EDB yum repository credentials for usage of any EDB tools.

  EDB_yumrepo_password = ""

  # Provide region name like East US where resource going to create.
  # Eg. region = "East US"

  region = ""
 
  # Enter Virtual Network Name. This is name of virtual network created in advance with CIDR range of your choise.
  # Eg. vnet_name = "testing-vnet"

  vnet_name = ""

  # Enter subnet name where instance going to create
  # Eg. subnetname = "default"

  subnetname = ""

  # Enter Azure Instance type like Standard_D2s_v3, Standard_B1ms  etc.
  # Eg. instance_size = "Standard_B1ms"

  instance_size = ""
  
  # Provide path of ssh public key file path. This file contains public key.
  # Eg. ssh_key_path = "/Users/edb/Documents/azurepubkey"

  ssh_key_path = ""
 
  # Enter Azure Network security group name. If left blank new security group will create and attached to newly created instance.
  # Eg. custom_security_group_name = "mynsg"

  custom_security_group_name = ""

  # Select replication type(synchronous or asynchronous). Leave it blank to use default replication type "asynchronous".

  replication_type = ""
  
  # Enter replication user password. This is password set for replication role while create 3 node DB cluster.
  # Eg. replication_password = "adminedb"

  replication_password = ""

  # Enter optional database (DB) User, leave it blank to use default user else enter desired user. 
 
  db_user = ""


 # Enter EFM notification email address
 # Eg. notification_email_address = "james@gmail.com"

 notification_email_address = ""

 # Enter EFM role password. This is a role created for failover operations. Provide password for it
 # Eg. efm_role_password = "admin"

  efm_role_password = ""

 # Enter Password of PEM WEB UI. Provide password which you have entered while creating PEM monitoring server. 
 # Eg. pem_web_ui_password = "adminpem"
 
  pem_web_ui_password = "" 

 # Enter DB password for new server.

  db_password = ""  

}  

output "Standby-PublicIP" {
  value = "${module.edb-expand-db-cluster.Slave-PublicIP}"
}

