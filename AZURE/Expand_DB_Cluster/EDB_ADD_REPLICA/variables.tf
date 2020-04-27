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

variable "ssh_key_path" {
   description = "Provide public ssh key path"
   type = string
}

variable "vnet_name" {
   type    = string
   description = "Enter Virtual Network Name"
}
  
variable "subnetname" {
  type        = string
  description = "The subnet name to use for instance creation."
}

variable "region" {
  description = "Provide region name where resource located"
  type = string
}


variable "instance_size" {
  description = "The type of instances to create."
  type        = string
}

variable "custom_security_group_name" {
  description = "Network Security group to assign to the instances."
  type        = string
  default     = ""
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


variable "notification_email_address" {
   description = "Enter email address where EFM notification will go"
   type = string
}

variable "efm_role_password" {
   description = "Enter password for DB role created from EFM operation"
   type        = string
}

variable "db_password" {
   description = "Enter DB password"
   type = string
}


variable "pem_web_ui_password" {
   description = "Enter password of pem server WEB UI"
   type        = string
}   
