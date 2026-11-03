variable "compartment_ocid" {
  type        = string
  description = "OCID do Compartment onde todos os recursos Always Free serão provisionados"
}

variable "region" {
  type        = string
  description = "Região da OCI (ex: sa-saopaulo-1)"
}

variable "oci_config_profile" {
  type        = string
  description = "Nome do perfil configurado no arquivo ~/.oci/config (ex: DEFAULT)"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Caminho no sistema operacional para o arquivo da chave SSH pública (ex: ~/.ssh/id_rsa.pub)"
}


variable "tag_project_arm" {
  type        = string
  description = "Valor da tag Project para as instâncias ARM"
}

variable "tag_project_vault" {
  type        = string
  description = "Valor da tag Project para a instância x86 Vault (ex: vault)"
}

variable "tag_project_vpn" {
  type        = string
  description = "Valor da tag Project para a instância x86 VPN (ex: VpnManagement)"
}

variable "bastion_client_cidr_block_allow_list" {
  type        = list(string)
  description = "Lista de blocos CIDR autorizados a conectar ao OCI Bastion (ex: [\"0.0.0.0/0\"])"
}
