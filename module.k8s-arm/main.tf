# Módulo cluster k8s
# Responsável pelo provisionamento do cluster Kubernetes (kubeadm) em instâncias ARM Ampere A1
# e do Load Balancer Always Free com IP público fixo reservado.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }
  }
}
