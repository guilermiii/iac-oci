# Network Security Group dedicado para as instâncias x86 (Isolamento em Subnet Privada)
resource "oci_core_network_security_group" "x86_nsg" {
  compartment_id = var.compartment_ocid
  vcn_id         = data.oci_core_subnet.selected.vcn_id
  display_name   = "nsg-x86-private"
}

data "oci_core_subnet" "selected" {
  subnet_id = var.subnet_id
}

# Ingress: Restrito estritamente à rede interna da VCN (10.0.0.0/16) - ZERO tráfego de entrada público
resource "oci_core_network_security_group_security_rule" "ingress_internal_only" {
  network_security_group_id = oci_core_network_security_group.x86_nsg.id
  direction                 = "INGRESS"
  protocol                  = "all"
  source_type               = "CIDR_BLOCK"
  source                    = "10.0.0.0/16"
  stateless                 = false
}

# Egress: Liberado via NAT Gateway para instalação de pacotes e updates
resource "oci_core_network_security_group_security_rule" "egress_all" {
  network_security_group_id = oci_core_network_security_group.x86_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination_type          = "CIDR_BLOCK"
  destination               = "0.0.0.0/0"
  stateless                 = false
}
