# IP Público Fixo Reservado (Always Free)
resource "oci_core_public_ip" "lb_fixed_ip" {
  compartment_id = var.compartment_ocid
  lifetime       = "RESERVED"
  display_name   = "pip-blog-do-zeca-fixed"

  freeform_tags = {
    "Project" = var.tag_project
  }
}

# Load Balancer Flexível de 10 Mbps (Always Free)
resource "oci_load_balancer_load_balancer" "lb" {
  compartment_id = var.compartment_ocid
  display_name   = "lb-blog-do-zeca"
  shape          = "flexible"

  shape_details {
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 10
  }

  subnet_ids = [var.public_subnet_id]
  is_private = false

  reserved_ips {
    id = oci_core_public_ip.lb_fixed_ip.id
  }

  freeform_tags = {
    "Project" = var.tag_project
  }
}

# Backend Set HTTP
resource "oci_load_balancer_backend_set" "http_backend_set" {
  load_balancer_id = oci_load_balancer_load_balancer.lb.id
  name             = "bs-http-blog"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol          = "TCP"
    port              = 80
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
}

# Listener HTTP na porta 80
resource "oci_load_balancer_listener" "http_listener" {
  load_balancer_id         = oci_load_balancer_load_balancer.lb.id
  name                     = "listener-http"
  default_backend_set_name = oci_load_balancer_backend_set.http_backend_set.name
  port                     = 80
  protocol                 = "HTTP"
}

# Registro do Worker Node no Backend Set
resource "oci_load_balancer_backend" "worker_backend" {
  load_balancer_id = oci_load_balancer_load_balancer.lb.id
  backendset_name  = oci_load_balancer_backend_set.http_backend_set.name
  ip_address       = oci_core_instance.worker.private_ip
  port             = 80
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}
