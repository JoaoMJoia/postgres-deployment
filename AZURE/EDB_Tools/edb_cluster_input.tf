###### Mandatory Fields in this config file #####

### region
### instance_size
### ssh_key_path
### subnetname
### vpc_id 
### replication_password
### s3bucket
### efm_role_password
### instance_type_pem
### ssh_keypair_pem
### subnet_id_pem
### ssh_key_path_pem
### db_password_pem
### EDB_yumrepo_username
### EDB_yumrepo_password

#############################################
### custom_security_group_name
### replication_type } by default asynchronous
### db_user
### db_password
### cluster_name
###########################################

### Default User DB credentials##########

### For EPAS12
## Username: enterprisedb
## Password: postgres

########################################


provider "azurerm" {
  version = "2.5"
  features {}
}


module "edb-db-cluster" {
  # The source module used for creating AWS clusters.
 
  source = "./EDB_Tools"
  
  # Enter EDB Yum Repository Credentials for usage of any EDB tools.

  EDB_yumrepo_username = ""

  # Enter EDB Yum Repository Credentials for usage of any EDB tools.

  EDB_yumrepo_password = ""

  # Provide Cluster name to be tagged. If you leave field blank we will use default value epas12.

  cluster_name = ""

  # Provide region name where resource going to create. Eg region = "East US".

  region = ""

  # Provide resource group name where resource will be placed.
  # Eg. rg_name = "testing"

  rg_name = ""

  # Enter this mandatory field which is Virtual network name. This you have to create with CIDR of your choise.
  # Eg. vnet_name = "testing-vnet"

  vnet_name = ""


  # Enter subnet name where instance going to create.
  # Eg. subnetname = "default"

  subnetname = ""

  # Enter Azure Instance type like Standard_D2s_v3, Standard_B1ms  etc.
  # Eg. instance_size = "Standard_B1ms"

  instance_size = ""
  
  # Enter Network Security group name. If left blank new network security group will create and attached to newly created VM.
  # Eg. custom_security_group_name = "mynsg"
 
  custom_security_group_name = ""
 
  # Provide storage account name. This storage account we will create on your behalf.
  # Eg. storage_account_name = "edbwalbackup"

  storage_account_name = ""

  # Provide Storage Container name where wal archive going to store. This also we will create on your behalf. 
  # Eg. container_name = "walfiles"

  container_name = ""

  # Provide path of ssh public key file path. This is public key file which contains your public key.
  # Eg. ssh_key_path = "/Users/edb/Documents/azurepubkey"

  ssh_key_path = "/Users/edb/Documents/azurepubkey"


  # Provide ssh private key file absolute path. This is ssh private key file used for ssh connectivity.
  # Eg. ssh_private_key_path = "/Users/edb/Documents/abc.pem"

  ssh_private_key_path = "" 

  # Enter optional database (DB) User, leave it blank to use default user else enter desired user. 
  # db_user = "john"
  
  
  db_user = ""

  # Enter custom database DB password. By default it is "postgres"

  db_password = ""
  
  # Enter replication type(synchronous or asynchronous). Leave it blank to use default replication type "asynchronous".

  replication_type = ""
  
  # Enter replication user password. This is replication role password created for replication operations.
  # replication_password = "admin"

  replication_password = ""


  #### EFM SET UP BEGINE HERE ####

  # Provide EFM role password. This is DB role password creted for failover operations.
  # Eg. efm_role_password = "adminefm"

  efm_role_password = ""

  # Provide EFM notification email address to receive cluster health notification or any change in status. 
  # Eg. notification_email_address = "james@gmail.com"
  
  notification_email_address = ""

 ### PEM MONITORING SERVER SETUP BEGINE HERE ###

  # Provide Instance Type for PEM monitoring server like Standard_D2s_v3, Standard_B1ms  etc.
  # instance_size_pem = "Standard_B1ms"

  instance_size_pem = ""

  # Provide custom Network security group for pem server. Leaving it blank will create new security group.
  # custom_security_group_name_pem = "mynsgpem"

   custom_security_group_name_pem = ""

  # Provide subnet name for pem monitoring server.
  # Eg. subnetname_pem = "default"

  subnetname_pem = ""

  # Provide public key pair file path for PEM monitoring server. This file contains public ssh key. 
  # Eg. ssh_keypair_path = "/Users/edb/Documents/azurepubkey"

  ssh_keypair_path = ""

  # Provide Key pair file path for PEM monitoring server. This is private key file path for ssh connectivity. 
  # Eg. ssh_private_key_path_pem = "/Users/edb/Documents/abc.pem"

  ssh_private_key_path_pem = ""

  # Provide DB password for PEM monitoring server.
  # Eg. db_password_pem = "adminpem"

  db_password_pem = ""

  #### BART SERVER SET UP BEGINE HERE ##

  # Enter subnet ID where instance going to create
  # Eg. subnetname_bart = "default"

  subnetname_bart = "default"

  # Enter Azure Instance size like Standard_D2s_v3, Standard_B1ms  etc.
  # Eg. instance_size_bart = "Standard_B1ms"

  instance_size_bart = ""
 

  # Enter SSH public key file path.  This file contains public ssh key. 
  # Eg. ssh_keypair_path = "/Users/edb/Documents/azurepubkey"

  ssh_keypair_bart = ""

  # Provide path of ssh private file path. This is private key file path for ssh connectivity.
  # Eg. ssh_private_key_path_pem = "/Users/edb/Documents/abc.pem"

  ssh_private_key_path_bart = ""

  # Specify the retention policy for the backup. This determines when an
  #  active backup should be marked as obsolete. You can specify the retention policy either in terms of number
  #  of backup or in terms of duration (days, weeks, or months). eg 3 MONTHS or 7 DAYS or 1 WEEK
  # Leave it blank if you dont want to specify retention period.
 
  retention_period = ""

  # Provide size of volume where bart server will take back up. This is just a number. For example size = 10 
  # will creare and attach volume of size 10GB

  size =  10
 
 
}  

output "A_Master-PublicIP" {
  value = "${module.edb-db-cluster.Master-IP}"
}

output "B_Standby1-PublicIP" {
  value = "${module.edb-db-cluster.Slave-IP-1}"
}

output "C_Standby2-PublicIP" {
  value = "${module.edb-db-cluster.Slave-IP-2}"
}

output "D_PEM-Server" {
  value = "${module.edb-db-cluster.PEM-Server}"
}

output "E_PEM-Agent1" {
  value = "${module.edb-db-cluster.Master-IP}"
}

output "F_PEM-Agent2" {
  value = "${module.edb-db-cluster.Slave-IP-1}"
}

output "G_PEM-Agent3" {
  value = "${module.edb-db-cluster.Slave-IP-2}"
}

output "H_Bart_SERVER_IP" {
  value = "${module.edb-db-cluster.Bart_SERVER_IP}"
}

output "I_EFM-Cluster" {
   value = "${module.edb-db-cluster.EFM-Cluster}"
}

