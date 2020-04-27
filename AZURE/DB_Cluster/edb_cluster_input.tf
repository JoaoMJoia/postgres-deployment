###### Mandatory Fields in this config file #####

### region
### instance_size
### vnet_name
### rg_name   
### ssh_key_path
### subnetname
### vn_name
### replication_password
### dbengine
### storage_account_name
### container_name
### ssh_private_key_path
#############################################

### Optional Field in this config file

### EDB_yumrepo_username } Mandatory if selecting dbengine epas(all version) 
### EDB_yumrepo_password }
### custom_security_group_name
### replication_type } by default asynchronous
### db_user
### db_password
### cluster_name

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


module "edb-db-cluster" {
  # The source module used for creating AWS clusters.
 
  source = "./EDB_SR_SETUP"
  
  # Enter EDB Yum Repository Credentials for usage of any EDB tools.

  EDB_yumrepo_username = ""

  # Enter EDB Yum Repository Credentials for usage of any EDB tools.

  EDB_yumrepo_password = ""

  # Provide tag name to DB cluster. Leaving it blank will tag instance as dbengine name.

  cluster_name = ""

  # Provide region name where resource going to create. Eg. region = "East US"

  region = ""

  # Provide resource group name. This is name of resource group where resource will present.

  rg_name = ""

  # Enter this mandatory field which is Virtual network name. This you have to create with choise of your CIDR range.
  # Eg. vnet_name = "testing-vnet"

  vnet_name = ""

  # Enter subnet name where instance going to create. You have to provide only name of subnet.
  # Eg. subnetname = "default"

  subnetname = ""

  # Enter VM size like Standard_D2s_v3, Standard_B1ms  etc.
  # Eg. instance_size = "Standard_B1ms" 

  instance_size = ""
  
 
  # Enter Network Security group name. If left blank new network security group will create and attached to newly created VM.
  # Eg. custom_security_group_name = "mynsg"
  # custom_security_group_name = ""   
 
  custom_security_group_name = "mynsg"

  # Provide storage account name. This storage account we will create on your behalf. 
  # Eg. storage_account_name = "edbwalbackup"

  storage_account_name = ""

  # Provide Storage Container name. In this container wal archive will store, again this we are creating on your behalf. 
  # container_name = "walfiles"

  container_name = ""

  # Provide path of ssh public key file. This absolute path of file which contains public key.
  # Eg. ssh_key_path = "/Users/edb/Documents/azurepubkey"

  ssh_key_path = ""

  # Select database engine(DB) version like pg10-postgresql version10, epas12-Enterprise Postgresql Advanced server etc..
  # DB version support V10-V12
  # Eg. dbengine = "pg10"
  # dbengine = "pg11"
  # dbengine = "pg12"
  # dbengine = "epas10"
  # dbengine = "epas11"
  # dbengine = "epas12"

  dbengine = ""

  # Enter optional database (DB) User, leave it blank to use default user else enter desired user. 
  # Eg. db_user = "john"
 
  db_user = ""

  # Enter custom database DB password. By default it is "postgres"
  
  db_password = ""
  
  # Enter replication type(synchronous or asynchronous). Leave it blank to use default replication type "asynchronous".

  replication_type = ""
  
  # Enter replication user password. This is password to role created for replication operations.
  # Eg. replication_password = "admin"

  replication_password = ""

  # Provide ssh private key file absolute path.
  # Eg. ssh_private_key_path = "/Users/edb/Documents/abc.pem"

  ssh_private_key_path = "" 

  
}  

output "Master-PublicIP" {
  value = "${module.edb-db-cluster.Master-IP}"
}

output "Standby1-PublicIP" {
  value = "${module.edb-db-cluster.Standby-IP-1}"
}

output "Standby2-PublicIP" {
  value = "${module.edb-db-cluster.Standby-IP-2}"
}

output "Master-PrivateIP" {
   value = "${module.edb-db-cluster.Master-PrivateIP}"
}

output "Standby1-PrivateIP" {
  value = "${module.edb-db-cluster.Standby-1-PrivateIP}"
}

output "Standby2-PrivateIP" {
  value = "${module.edb-db-cluster.Standby-2-PrivateIP}"
}

output "DBENGINE" {
  value = "${module.edb-db-cluster.DBENGINE}"
}


output "Key-Pair-Path" {
  value = "${module.edb-db-cluster.Key-Pair-Path}"
}

output "STORAGE_ACCOUNT_NAME" {
  value = "${module.edb-db-cluster.STORAGE_ACCOUNT_NAME}"
}

output "RG_NAME" {
  value = "${module.edb-db-cluster.RG_NAME}"
}

output "Container_Name" {
  value = "${module.edb-db-cluster.Container_Name}"
}

output "CLUSTER_NAME" {
  value = "${module.edb-db-cluster.CLUSTER_NAME}"
}



