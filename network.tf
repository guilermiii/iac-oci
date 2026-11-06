# VCN Principal (Virtual Cloud Network)
resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "vcn-always-free"
  dns_label      = "ociblogvcn"
}

# Internet Gateway para tráfego público (Load Balancer)
resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "igw-always-free"
  enabled        = true
}

# NAT Gateway para permitir updates/bootstrap nas subnets privadas sem ingress público
resource "oci_core_nat_gateway" "nat_gw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "natgw-always-free"
}

# Tabela de Roteamento para a Subnet Pública (0.0.0.0/0 -> Internet Gateway)
resource "oci_core_route_table" "public_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "rt-public"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

# Tabela de Roteamento para a Subnet Privada (0.0.0.0/0 -> NAT Gateway)
resource "oci_core_route_table" "private_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "rt-private"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gw.id
  }
}

# Security List para a Subnet Pública (Apenas portas Web para o Load Balancer)
resource "oci_core_security_list" "public_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "seclist-public-lb"

  # Egress liberado para todas as direções
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  # Ingress HTTP (Porta 80)
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 80
      max = 80
    }
  }

  # Ingress HTTPS (Porta 443)
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 443
      max = 443
    }
  }
}

# Security List para a Subnet Privada (Comunicação interna segura e saída via NAT)
resource "oci_core_security_list" "private_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "seclist-private-nodes"

  # Egress total via NAT Gateway para updates de pacotes e imagens
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  # Ingress interno restrito à VCN (10.0.0.0/16) para K8s, Flannel e comunicação inter-nós
  ingress_security_rules {
    protocol  = "all"
    source    = "10.0.0.0/16"
    stateless = false
  }
}

# Subnet Pública (Onde reside o Load Balancer com IP Fixo Reservado)
resource "oci_core_subnet" "public_subnet" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.main.id
  cidr_block                 = "10.0.1.0/24"
  display_name               = "subnet-public"
  dns_label                  = "subpublic"
  route_table_id             = oci_core_route_table.public_route_table.id
  security_list_ids          = [oci_core_security_list.public_security_list.id]
  prohibit_public_ip_on_vnic = false
}

# Subnet Privada (Onde residem os nós K8s ARM e instâncias x86, sem IP público)
resource "oci_core_subnet" "private_subnet" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.main.id
  cidr_block                 = "10.0.2.0/24"
  display_name               = "subnet-private"
  dns_label                  = "subprivate"
  route_table_id             = oci_core_route_table.private_route_table.id
  security_list_ids          = [oci_core_security_list.private_security_list.id]
  prohibit_public_ip_on_vnic = true
}

# ==============================================================================
# Gestão Explícita de Recursos Default da VCN (Prática recomendada CIS Benchmark)
# Mantém os recursos default rastreados no Terraform e limpos/isolados
# ==============================================================================

# Route Table Padrão da VCN (isolada sem rotas para assegurar uso de rt-public e rt-private)
resource "oci_core_default_route_table" "default_route_table" {
  manage_default_resource_id = oci_core_vcn.main.default_route_table_id
  display_name               = "rt-default"
}

# Security List Padrão da VCN (sem regras permissivas padrão para assegurar uso de seclists dedicadas)
resource "oci_core_default_security_list" "default_security_list" {
  manage_default_resource_id = oci_core_vcn.main.default_security_list_id
  display_name               = "seclist-default"
}
