# Módulo instancias x86
# Responsável pelo provisionamento das instâncias x86 VM.Standard.E2.1.Micro
# dedicadas a Vault e VPN Management em Subnet Privada (sem tráfego público de entrada).

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }
  }
}
