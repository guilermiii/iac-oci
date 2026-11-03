# Instância x86 Micro: Vault
resource "oci_core_instance" "vault" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain_name
  display_name        = "x86-vault"
  shape               = "VM.Standard.E2.1.Micro"

  source_details {
    source_type             = "image"
    source_id               = var.ubuntu_x86_image_ocid
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = false
    hostname_label   = "vault"
    nsg_ids          = [oci_core_network_security_group.x86_nsg.id]
  }

  metadata = {
    ssh_authorized_keys = file(pathexpand(var.ssh_public_key_path))
    user_data           = base64encode(file("${path.module}/cli/vault.sh"))
  }

  freeform_tags = {
    "Project" = var.tag_vault
  }
}

# Instância x86 Micro: VPN Management
resource "oci_core_instance" "vpn" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain_name
  display_name        = "x86-vpn"
  shape               = "VM.Standard.E2.1.Micro"

  source_details {
    source_type             = "image"
    source_id               = var.ubuntu_x86_image_ocid
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = false
    hostname_label   = "vpn"
    nsg_ids          = [oci_core_network_security_group.x86_nsg.id]
  }

  metadata = {
    ssh_authorized_keys = file(pathexpand(var.ssh_public_key_path))
    user_data           = base64encode(file("${path.module}/cli/vpn.sh"))
  }

  freeform_tags = {
    "Project" = var.tag_vpn
  }
}
