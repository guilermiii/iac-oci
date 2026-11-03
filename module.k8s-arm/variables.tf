variable "compartment_ocid" {
  type        = string
  description = "OCID do Compartment para os recursos do cluster Kubernetes"
}

variable "availability_domain_name" {
  type        = string
  description = "Nome do Availability Domain para provisionamento das instâncias ARM"
}

variable "subnet_id" {
  type        = string
  description = "OCID da Subnet Privada para alocação das instâncias ARM do K8s"
}

variable "public_subnet_id" {
  type        = string
  description = "OCID da Subnet Pública para alocação do Load Balancer com IP fixo"
}

variable "ubuntu_arm_image_ocid" {
  type        = string
  description = "OCID da imagem oficial Ubuntu 24.04 LTS aarch64 para ARM"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Caminho no filesystem para o arquivo da chave SSH pública"
}

variable "tag_project" {
  type        = string
  description = "Tag de identificação do projeto (Blog-do-Zeca)"
}

variable "arm_ocpus" {
  type        = number
  description = "Quantidade de OCPUs por instância ARM A1 Flex (ex: 2)"
}

variable "arm_memory_in_gbs" {
  type        = number
  description = "Quantidade de memória RAM em GB por instância ARM A1 Flex (ex: 12)"
}

variable "boot_volume_size_in_gbs" {
  type        = number
  description = "Tamanho em GB do boot volume (ex: 50 conforme Always Free)"
}
