terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.10.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.12.1"
    }
  }
  required_version = ">= 1.3.0"
}

data "sops_file" "secrets" {
  source_file = "secret.sops.yaml"
}
