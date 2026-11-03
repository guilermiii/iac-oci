output "load_balancer_public_ip" {
  value       = oci_core_public_ip.lb_fixed_ip.ip_address
  description = "IP Público Fixo Reservado do Load Balancer"
}

output "load_balancer_id" {
  value       = oci_load_balancer_load_balancer.lb.id
  description = "OCID do Load Balancer"
}

output "control_plane_private_ip" {
  value       = oci_core_instance.control_plane.private_ip
  description = "IP Privado do nó Control Plane do Kubernetes"
}

output "control_plane_id" {
  value       = oci_core_instance.control_plane.id
  description = "OCID da instância Control Plane"
}

output "worker_private_ip" {
  value       = oci_core_instance.worker.private_ip
  description = "IP Privado do nó Worker do Kubernetes"
}

output "worker_id" {
  value       = oci_core_instance.worker.id
  description = "OCID da instância Worker"
}
