variable "compartment_ocid" {
  type        = string
  description = "OCID do Compartment onde todos os recursos Always Free serão provisionados"
  default     = "ocid1.compartment.oc1..aaaaaaaa7qb7s6k27ewo6oyylxa7qguh3xkqlijnhqk7hyz3oyncznn2fx3a"
}

variable "tenancy_ocid" {
  type        = string
  description = "OCID do Tenancy onde todos os recursos Always Free serão provisionados"
}

variable "region" {
  type        = string
  description = "Região da OCI (ex: sa-saopaulo-1)"
  default     = "sa-saopaulo-1"
}

variable "oci_config_profile" {
  type        = string
  description = "Nome do perfil configurado no arquivo ~/.oci/config (ex: DEFAULT)"
  default     = "DEFAULT"
}

variable "ssh_public_key_value" {
  type        = string
  description = "Valor da chave injetada nas instancias"
}

variable "auth" {
  type        = string
  description = "Tipo de autenticação"
  default     = "SecurityToken"
}

variable "tag_project_arm" {
  type        = string
  description = "Valor da tag Project para as instâncias ARM"
  default     = "Cluster K8s"
}

variable "tag_project_vault" {
  type        = string
  description = "Valor da tag Project para a instância x86 Vault (ex: vault)"
  default     = "vault"
}

variable "tag_project_vpn" {
  type        = string
  description = "Valor da tag Project para a instância x86 VPN (ex: VpnManagement)"
  default     = "VpnManagement"
}

variable "bastion_client_cidr_block_allow_list" {
  type        = list(string)
  description = "Lista de blocos CIDR autorizados a conectar ao OCI Bastion (ex: [\"0.0.0.0/0\"])"
  default     = ["0.0.0.0/0"]
}

variable "enable_x86_instances" {
  type        = bool
  description = "Controla o provisionamento das instâncias x86 Micro (Vault e VPN). Mantenha false caso o limite Always Free de 2 instâncias Micro já esteja em uso no tenancy."
  default     = false
}
