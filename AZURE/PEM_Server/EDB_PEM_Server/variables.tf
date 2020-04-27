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

  
variable "subnetname" {
  type        = string
  description = "The subnet name to use for instance creation."
}

variable "custom_security_group_name" {
   description = "Custom network security group"
   type = string
   default = ""
}

variable "vnet_name" {
  description = "The virtual network to use."
  type        = string
}

variable "rg_name" {
  description = "The resource group name to use"
  type  = string
}

variable "region" {
  description = "Provide region name"
  type = string
}



variable "instance_size" {
  description = "The type of instances to create."
  type        = string
}

variable "custom_security_group_id" {
  description = "Security group to assign to the instances."
  type        = string
  default     = ""
}


variable "ssh_key_path" {
  description = "SSH public key path from local machine"
  type = string
}

variable "ssh_private_key_path" {
  description = "SSH private key path from local machine"
  type = string
}


variable "db_password" {
   description = "Enter DB password of your choice"
   type = string
}

