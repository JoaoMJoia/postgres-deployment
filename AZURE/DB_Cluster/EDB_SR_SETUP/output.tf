output "Master-IP" {
value = azurerm_linux_virtual_machine.edb_vm[0].public_ip_address
}

output "Standby-IP-1" {
value = azurerm_linux_virtual_machine.edb_vm[1].public_ip_address
}

output "Standby-IP-2" {
value = azurerm_linux_virtual_machine.edb_vm[2].public_ip_address
}


output "Master-PrivateIP" {
value = azurerm_linux_virtual_machine.edb_vm[0].private_ip_address
}

output "Standby-1-PrivateIP" {
value = azurerm_linux_virtual_machine.edb_vm[1].private_ip_address
}

output "Standby-2-PrivateIP" {
value = azurerm_linux_virtual_machine.edb_vm[2].private_ip_address
}

output "DBENGINE" {
value = var.dbengine
}




output "Key-Pair-Path" {
value = var.ssh_private_key_path
}


output "DBUSER" {
value = var.db_user
}


output "STORAGE_ACCOUNT_NAME" {
value = var.storage_account_name
}

output "RG_NAME" {
value = var.rg_name
}

output "Container_Name" {
value = var.container_name
}

output "CLUSTER_NAME" {
value = var.cluster_name
} 
