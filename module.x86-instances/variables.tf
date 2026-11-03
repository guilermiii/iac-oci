variable "compartment_ocid" {
  type        = string
  description = "OCID do Compartment para as instâncias x86"
}

variable "availability_domain_name" {
  type        = string
  description = "Nome do Availability Domain para provisionamento das instâncias x86"
}

variable "subnet_id" {
  type        = string
  description = "OCID da Subnet Privada para alocação das instâncias x86 (sem IP público)"
}

variable "ubuntu_x86_image_ocid" {
  type        = string
  description = "OCID da imagem oficial Ubuntu 24.04 LTS x86_64 para as instâncias Micro"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Caminho no filesystem para o arquivo da chave SSH pública"
}

variable "tag_vault" {
  type        = string
  description = "Tag de identificação do projeto para a instância Vault (vault)"
}

variable "tag_vpn" {
  type        = string
  description = "Tag de identificação do projeto para a instância VPN (VpnManagement)"
}

variable "boot_volume_size_in_gbs" {
  type        = number
  description = "Tamanho em GB do boot volume (ex: 50 conforme Always Free)"
}
