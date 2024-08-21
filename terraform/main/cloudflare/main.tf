terraform {

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.40.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.4"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.0.0"
    }
  }
}

data "sops_file" "cloudflare_secrets" {
  source_file = "secret.sops.yaml"
}

data "http" "ipv4_lookup_raw" {
  url = "http://ipv4.icanhazip.com"
}

data "cloudflare_zone" "domain" {
  name = data.sops_file.cloudflare_secrets.data["cloudflare_domain_ingress"]
}

data "cloudflare_zone" "home" {
  name = data.sops_file.cloudflare_secrets.data["cloudflare_domain_ingress"]
}
