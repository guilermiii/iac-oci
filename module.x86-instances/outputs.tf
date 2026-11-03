output "vault_private_ip" {
  value       = oci_core_instance.vault.private_ip
  description = "IP Privado da instância Vault"
}

output "vault_id" {
  value       = oci_core_instance.vault.id
  description = "OCID da instância Vault"
}

output "vpn_private_ip" {
  value       = oci_core_instance.vpn.private_ip
  description = "IP Privado da instância VPN Management"
}

output "vpn_id" {
  value       = oci_core_instance.vpn.id
  description = "OCID da instância VPN Management"
}
