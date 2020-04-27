variable "EDB_yumrepo_username" {
  description = "yum repo user name"
  default     = ""
  type        = string
}

variable "EDB_yumrepo_password" {
  description = "yum repo user password"
  default     = ""
  type        = string
}

variable "vnet_name" {
   type    = string
   description = "Enter Virtual network name"
}
  
variable "subnetname" {
  type        = string
  description = "The subnetname to use for instance creation."
}

variable "region" {
  description = "Provide region name where resource going to create"
  type = string
}

variable "rg_name" {
   description = "Provide resource group name"
   type = string
}


variable "instance_size" {
  description = "The type of instances to create."
  default     = "c4.xlarge"
  type        = string
}

variable "custom_security_group_name" {
  description = "Network Security group assign to the instances."
  type        = string
}


variable "storage_account_name" {
  description = "Provide storage account name"
  type = string
}

variable "container_name" {
  description = "Provide storage container name"
  type = string
}

variable "ssh_key_path" {
  description = "Provide public key file path"
  type = string
}
  

variable "ssh_private_key_path" {
  description = "SSH private key path from local machine"
  type = string
}


variable "replication_type" {
   description = "Select replication type asynchronous or synchronous"
   type = string
   default = "asynchronous"
}

variable "replication_password" {
   description = "Enter replication password of your choice"
   type = string
}

variable "db_user" {
   description = "Enter optional DB user name"
   type = string
}

variable "db_password" {
   description = "Enter custom DB password"
   type = string
   default = "postgres"
}


variable "efm_role_password" { 
   description = "Provide efm role password"
   type = string
}

variable "notification_email_address" {
   description = "Provide notification email address"
   type = string
}

variable "db_password_pem" {
   description = "Provide pem server DB password"
   type = string
}


variable "instance_size_pem" {
   description = "Provide instance type for pem server"
   type = string
}

variable "ssh_keypair_path" {
   description = "Provide ssh keypair for pemserver"
   type = string
}

variable "subnetname_pem" {
   description = "Provide subnet ID for pem server"
   type = string
}

variable "ssh_private_key_path_pem" {
   description = "Provide ssh key path for pem server"
   type = string
}


variable "custom_security_group_name_pem" {
   description = "Provide custom security group"
   type = string
}    

variable "subnetname_bart" {
  type        = string
  description = "The subnet-id to use for instance creation."
}

variable "instance_size_bart" {
  description = "The type of instances to create."
  type        = string
}


variable "ssh_keypair_bart" {
  description = "The SSH key pair name"
  type = string
}

variable "ssh_private_key_path_bart" {
  description = "SSH private key path from local machine"
  type = string
}

variable "retention_period" {
   description = "Enter retension period"
   default = ""
   type = string
}

variable "size" {
   description = "Enter size of volume for bart backup"
   type = number
}

variable "cluster_name" {
   description = "Provide cluster name"
   type = string
}

