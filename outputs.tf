output "resource_group_name" {
  description = "Resource group holding the landing zone."
  value       = azurerm_resource_group.rg.name
}

output "storage_account_name" {
  description = "Name of the locked-down storage account."
  value       = azurerm_storage_account.sa.name
}

output "storage_blob_fqdn" {
  description = "Resolve this from inside the VNet (nslookup) to prove it returns a private 10.1.x.x address, not a public one."
  value       = "${azurerm_storage_account.sa.name}.blob.core.windows.net"
}

output "private_endpoint_private_ip" {
  description = "The private IP the storage account is reachable on from inside the network."
  value       = azurerm_private_endpoint.blob.private_service_connection[0].private_ip_address
}
