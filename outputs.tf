output "load_balancer_public_ip" {
  value       = module.blog_do_zeca.load_balancer_public_ip
  description = "IP Público Fixo Reservado do Load Balancer (Blog do Zeca)"
}

output "k8s_control_plane_private_ip" {
  value       = module.blog_do_zeca.control_plane_private_ip
  description = "IP Privado do nó Control Plane do Kubernetes"
}

output "k8s_worker_private_ip" {
  value       = module.blog_do_zeca.worker_private_ip
  description = "IP Privado do nó Worker do Kubernetes"
}

output "vault_private_ip" {
  value       = var.enable_x86_instances ? module.x86[0].vault_private_ip : null
  description = "IP Privado da instância x86 Vault"
}

output "vpn_private_ip" {
  value       = var.enable_x86_instances ? module.x86[0].vpn_private_ip : null
  description = "IP Privado da instância x86 VPN Management"
}

output "vpn_public_ip" {
  value       = var.enable_x86_instances ? module.x86[0].vpn_public_ip : null
  description = "IP Público Efêmero da instância x86 VPN Management (DuckDNS WireGuard)"
}

output "discovered_availability_domain" {
  value       = data.oci_identity_availability_domains.ads.availability_domains[0].name
  description = "Availability Domain selecionado automaticamente"
}

output "discovered_ubuntu_arm_image" {
  value       = data.oci_core_images.ubuntu_arm.images[0].display_name
  description = "Imagem Ubuntu 24.04 ARM selecionada automaticamente"
}

output "discovered_ubuntu_x86_image" {
  value       = data.oci_core_images.ubuntu_x86.images[0].display_name
  description = "Imagem Ubuntu 24.04 x86 selecionada automaticamente"
}

output "k8s_join_instruction" {
  value       = "Acesse o nó Control Plane para obter o comando gerado em /home/ubuntu/kubeadm-join.sh e execute-o no Worker."
  description = "Instrução para conectar o worker ao cluster Kubernetes"
}

output "bastion_id" {
  value       = oci_bastion_bastion.bastion.id
  description = "OCID do OCI Bastion Service"
}

output "bastion_target_subnet_id" {
  value       = oci_bastion_bastion.bastion.target_subnet_id
  description = "OCID da Subnet Privada associada ao Bastion"
}
