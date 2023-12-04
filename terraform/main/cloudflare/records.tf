resource "cloudflare_record" "apex" {
  name    = "ipv4"
  zone_id = data.cloudflare_zone.domain.id
  value   = chomp(data.http.ipv4_lookup_raw.response_body)
  proxied = true
  type    = "A"
  ttl     = 1
}

resource "cloudflare_record" "root" {
  name    = data.sops_file.cloudflare_secrets.data["cloudflare_domain_ingress"]
  zone_id = data.cloudflare_zone.domain.id
  value   = "ipv4.${data.sops_file.cloudflare_secrets.data["cloudflare_domain_ingress"]}"
  proxied = true
  type    = "CNAME"
  ttl     = 1
}

# resource "cloudflare_record" "home_cname" {
#   name    = module.onepassword_item.fields["CLOUDFLARE_DIRECT_CNAME"]
#   zone_id = data.cloudflare_zone.domain.id
#   value   = "ipv4.devbu.io"
#   proxied = false
#   type    = "CNAME"
#   ttl     = 1
# }
