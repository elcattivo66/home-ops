resource "cloudflare_account" "main" {
  name              = "homers66"
  type              = "standard"
  enforce_twofactor = false
}
