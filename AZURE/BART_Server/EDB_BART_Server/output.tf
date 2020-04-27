output "Bart-IP" {
  value = "${azurerm_linux_virtual_machine.EDB_Bart_Server.public_ip_address}"
}

