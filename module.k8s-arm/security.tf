# Network Security Group dedicado para o cluster Kubernetes (Blog do Zeca)
resource "oci_core_network_security_group" "k8s_nsg" {
  compartment_id = var.compartment_ocid
  vcn_id         = split("/", var.subnet_id)[0] != "" ? data.oci_core_subnet.selected.vcn_id : ""
  display_name   = "nsg-blog-do-zeca-k8s"

  freeform_tags = {
    "Project" = var.tag_project
  }
}

data "oci_core_subnet" "selected" {
  subnet_id = var.subnet_id
}

# Regra de Ingress: Tráfego HTTP (porta 80) e HTTPS (porta 443) a partir da Subnet Pública (Load Balancer)
resource "oci_core_network_security_group_security_rule" "ingress_http_from_lb" {
  network_security_group_id = oci_core_network_security_group.k8s_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source_type               = "CIDR_BLOCK"
  source                    = "10.0.1.0/24" # Subnet pública do Load Balancer
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

# Regra de Ingress: NodePort Services (30000-32767) a partir da Subnet Pública (Load Balancer)
resource "oci_core_network_security_group_security_rule" "ingress_nodeport_from_lb" {
  network_security_group_id = oci_core_network_security_group.k8s_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source_type               = "CIDR_BLOCK"
  source                    = "10.0.1.0/24"
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 30000
      max = 32767
    }
  }
}

# Regra de Ingress: Kubelet API (10250) interna entre nós
resource "oci_core_network_security_group_security_rule" "ingress_kubelet" {
  network_security_group_id = oci_core_network_security_group.k8s_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source_type               = "CIDR_BLOCK"
  source                    = "10.0.2.0/24" # Subnet privada
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 10250
      max = 10250
    }
  }
}

# Regra de Ingress: API Server (6443) interna
resource "oci_core_network_security_group_security_rule" "ingress_k8s_apiserver" {
  network_security_group_id = oci_core_network_security_group.k8s_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source_type               = "CIDR_BLOCK"
  source                    = "10.0.2.0/24"
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

# Regra de Ingress: CNI Flannel Overlay (UDP 8472)
resource "oci_core_network_security_group_security_rule" "ingress_flannel" {
  network_security_group_id = oci_core_network_security_group.k8s_nsg.id
  direction                 = "INGRESS"
  protocol                  = "17" # UDP
  source_type               = "CIDR_BLOCK"
  source                    = "10.0.2.0/24"
  stateless                 = false

  udp_options {
    destination_port_range {
      min = 8472
      max = 8472
    }
  }
}

# Regra de Ingress: SSH (porta 22) para acesso administrativo via OCI Bastion
resource "oci_core_network_security_group_security_rule" "ingress_ssh_bastion" {
  network_security_group_id = oci_core_network_security_group.k8s_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source_type               = "CIDR_BLOCK"
  source                    = "10.0.0.0/16"
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}
