# Orquestração Principal da Infraestrutura OCI Always Free

# Módulo 1: Cluster Kubernetes ARM (Blog do Zeca) + Load Balancer Flexível com IP Fixo Reservado
module "blog_do_zeca" {
  source = "./module.k8s-arm"

  compartment_ocid         = var.compartment_ocid
  availability_domain_name = data.oci_identity_availability_domains.ads.availability_domains[0].name
  subnet_id                = oci_core_subnet.private_subnet.id
  public_subnet_id         = oci_core_subnet.public_subnet.id
  ubuntu_arm_image_ocid    = data.oci_core_images.ubuntu_arm.images[0].id
  ##ssh_public_key_path      = var.ssh_public_key_path
  ssh_public_key_value    = var.ssh_public_key_value
  tag_project             = var.tag_project_arm
  arm_ocpus               = 2
  arm_memory_in_gbs       = 12
  boot_volume_size_in_gbs = 50
}

# Módulo 2: Instâncias x86 Micro (Vault & VPN Management) em Subnet Privada
module "x86" {
  count  = var.enable_x86_instances ? 1 : 0
  source = "./module.x86-instances"

  compartment_ocid         = var.compartment_ocid
  availability_domain_name = data.oci_identity_availability_domains.ads.availability_domains[0].name
  subnet_id                = oci_core_subnet.private_subnet.id
  ubuntu_x86_image_ocid    = data.oci_core_images.ubuntu_x86.images[0].id
  ssh_public_key_value     = var.ssh_public_key_value
  ##ssh_public_key_path      = var.ssh_public_key_path
  tag_vault               = var.tag_project_vault
  tag_vpn                 = var.tag_project_vpn
  boot_volume_size_in_gbs = 50
}
