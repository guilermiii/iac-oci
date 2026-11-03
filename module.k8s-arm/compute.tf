# Instância ARM: Control Plane Node
resource "oci_core_instance" "control_plane" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain_name
  display_name        = "k8s-control-plane"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.arm_ocpus
    memory_in_gbs = var.arm_memory_in_gbs
  }

  source_details {
    source_type             = "image"
    source_id               = var.ubuntu_arm_image_ocid
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = false
    hostname_label   = "k8scp"
    nsg_ids          = [oci_core_network_security_group.k8s_nsg.id]
  }

  metadata = {
    ssh_authorized_keys = file(pathexpand(var.ssh_public_key_path))
    user_data           = base64encode(file("${path.module}/cli/controlplane.sh"))
  }

  freeform_tags = {
    "Project" = var.tag_project
  }
}

# Instância ARM: Worker Node
resource "oci_core_instance" "worker" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain_name
  display_name        = "k8s-worker"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.arm_ocpus
    memory_in_gbs = var.arm_memory_in_gbs
  }

  source_details {
    source_type             = "image"
    source_id               = var.ubuntu_arm_image_ocid
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = false
    hostname_label   = "k8sworker"
    nsg_ids          = [oci_core_network_security_group.k8s_nsg.id]
  }

  metadata = {
    ssh_authorized_keys = file(pathexpand(var.ssh_public_key_path))
    user_data           = base64encode(file("${path.module}/cli/worker.sh"))
  }

  freeform_tags = {
    "Project" = var.tag_project
  }
}
