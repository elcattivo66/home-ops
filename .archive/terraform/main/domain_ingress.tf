module "cf_domain_ingress" {
  source     = "./modules/cf_domain"
  domain     = "${data.sops_file.cloudflare_secrets.data["cloudflare_domain_ingress"]}"
  account_id = cloudflare_account.main.id
  dns_entries = [
    {
      name  = "ipv4"
      value = local.home_ipv4
    },
    {
      name    = "minio"
      value   = "ipv4.${data.sops_file.cloudflare_secrets.data["cloudflare_domain_ingress"]}"
      proxied = false
      type    = "CNAME"
      ttl     = 1
    },

    # Generic settings
    {
      name  = "_dmarc"
      value = "v=DMARC1; p=quarantine;"
      type  = "TXT"
    }
  ]

  waf_custom_rules = [
    {
      enabled     = true
      description = "Allow GitHub flux API"
      expression  = "(ip.geoip.asnum eq 36459 and http.host eq \"flux-webhook.${data.sops_file.cloudflare_secrets.data["cloudflare_domain_ingress"]}\")"
      action      = "skip"
      action_parameters = {
        ruleset = "current"
      }
      logging = {
        enabled = false
      }
    },
    {
      enabled     = true
      description = "Firewall rule to block bots and threats determined by CF"
      expression  = "(cf.client.bot) or (cf.threat_score gt 14)"
      action      = "block"
    },
    {
      enabled     = true
      description = "Firewall rule to block certain countries"
      expression  = "(ip.geoip.country in {\"CN\" \"IN\" \"KP\" \"RU\"})"
      action      = "block"
    },
  ]
}
