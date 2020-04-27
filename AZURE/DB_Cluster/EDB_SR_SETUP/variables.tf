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

  
variable "rg_name" {
  type        = string
  description = "The resource group name."
}


variable "subnetname" {
  description = "Name of the subnet created in network"
  type        = string
}

variable "vnet_name" {
  description = "Provide virtual network name"
  type = string
}
 

variable "region" {
  description = "The region where resource going to create"
  type = string 
}


variable "custom_security_group_name" {
  description = "Security group assign to the instances."
  type        = string
  default     = ""
}


variable "instance_size" {
   description = "Provide size of instance"
   type = string
}

variable "ssh_key_path" {
  description = "SSH public key path from local machine"
  type = string
}


variable "dbengine" {
   description = "Select dbengine from pg10, pg11, pg12, epas10, epas11, epas12"
   type = string
   default = "pg12"
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


variable "cluster_name" {
   description = "Provide cluster name"
   type = string
}

variable "storage_account_name" {
   description = "Provide storage account name to create"
   type = string
}

variable "ssh_private_key_path" {
   description = "Provide private key file path for ssh"
   type = string
}

variable "container_name" {
   description = "Provide storage container name"
   type = string
} 
