output "Master-IP" {
value = azurerm_linux_virtual_machine.edb_vm[0].public_ip_address
}
output "Slave-IP-1" {
value = azurerm_linux_virtual_machine.edb_vm[1].public_ip_address
}
output "Slave-IP-2" {
value = azurerm_linux_virtual_machine.edb_vm[2].public_ip_address
}


output "PEM-Server" {
value = azurerm_linux_virtual_machine.EDB_Pem_Server.public_ip_address
}

output "PEM-Agent1" {
value = azurerm_linux_virtual_machine.edb_vm[0].public_ip_address
}

output "PEM-Agent2" {
value = azurerm_linux_virtual_machine.edb_vm[1].public_ip_address
}


output "PEM-Agent3" {
value = azurerm_linux_virtual_machine.edb_vm[2].public_ip_address
}

output "Bart_SERVER_IP" {
value = azurerm_linux_virtual_machine.EDB_Bart_Server.public_ip_address
}  

output "EFM-Cluster" {
value = "${join(",", azurerm_linux_virtual_machine.edb_vm.*.private_ip_address)}"
}

