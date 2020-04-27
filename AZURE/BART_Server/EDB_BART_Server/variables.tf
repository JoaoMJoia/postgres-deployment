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
  description = "Provide virtual network name"
  type = string
}

variable "rg_name" {
  description = "Provide resource group name"
  type = string
}

variable "region" {
  description = "Provide Azure region name"
  type = string
}


  
variable "subnetname" {
  type        = string
  description = "The subnet name to use for instance creation."
}


variable "instance_size" {
  description = "The type of instances to create."
  type        = string
}



variable "ssh_private_key_path" {
  description = "The SSH private key pair path" 
  type = string
}

variable "ssh_key_path" {
  description = "SSH public key path from local machine"
  type = string
}

variable "db_password" {
   description = "Enter DB password of remote server"
   type = string
}

variable "db_user" {
    description = "Provide DB user name"
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

variable  "bart_user" {
   description = "Provide Bart User name"
   type = string
   default = "enterprisedb"
}
   
