# Network Security Group dedicado para a instância Vault (Isolamento em Subnet Privada)
resource "oci_core_network_security_group" "x86_nsg" {
  compartment_id = var.compartment_ocid
  vcn_id         = data.oci_core_subnet.selected.vcn_id
  display_name   = "nsg-vault-private"
}

data "oci_core_subnet" "selected" {
  subnet_id = var.subnet_id
}

# Ingress Vault: Restrito estritamente à Subnet Privada (10.0.2.0/24) - Sem acesso da VPN pública
resource "oci_core_network_security_group_security_rule" "vault_ingress_internal_only" {
  network_security_group_id = oci_core_network_security_group.x86_nsg.id
  direction                 = "INGRESS"
  protocol                  = "all"
  source_type               = "CIDR_BLOCK"
  source                    = data.oci_core_subnet.selected.cidr_block
  stateless                 = false
}

# Egress Vault: Liberado via NAT Gateway para instalação de pacotes e updates
resource "oci_core_network_security_group_security_rule" "vault_egress_all" {
  network_security_group_id = oci_core_network_security_group.x86_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination_type          = "CIDR_BLOCK"
  destination               = "0.0.0.0/0"
  stateless                 = false
}

# ==============================================================================
# Network Security Group dedicado para a instância VPN WireGuard (Subnet Pública)
# ==============================================================================
resource "oci_core_network_security_group" "vpn_nsg" {
  compartment_id = var.compartment_ocid
  vcn_id         = data.oci_core_subnet.selected.vcn_id
  display_name   = "nsg-vpn-public"
}

# Ingress VPN: WireGuard porta UDP 51820 aberta para conexão client-to-site / on-premise
resource "oci_core_network_security_group_security_rule" "vpn_ingress_wireguard" {
  network_security_group_id = oci_core_network_security_group.vpn_nsg.id
  direction                 = "INGRESS"
  protocol                  = "17" # UDP
  source_type               = "CIDR_BLOCK"
  source                    = "0.0.0.0/0"
  stateless                 = false

  udp_options {
    destination_port_range {
      min = 51820
      max = 51820
    }
  }
}

# Ingress VPN: SSH (TCP 22) restrito ao OCI Bastion (Subnet Privada 10.0.2.0/24)
resource "oci_core_network_security_group_security_rule" "vpn_ingress_ssh_bastion" {
  network_security_group_id = oci_core_network_security_group.vpn_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source_type               = "CIDR_BLOCK"
  source                    = data.oci_core_subnet.selected.cidr_block
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

# Egress VPN: Direto à Internet via Internet Gateway (updates DuckDNS e respostas VPN)
resource "oci_core_network_security_group_security_rule" "vpn_egress_all" {
  network_security_group_id = oci_core_network_security_group.vpn_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination_type          = "CIDR_BLOCK"
  destination               = "0.0.0.0/0"
  stateless                 = false
}
