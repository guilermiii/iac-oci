terraform {
  backend "oci" {
    bucket              = "tf-state-lock-blog"
    namespace           = "gr2g4g6jibse"
    region              = "sa-saopaulo-1"
    key                 = "terraform.tfstate"
    auth                = "SecurityToken"
    config_file_profile = "DEFAULT"
  }
}
