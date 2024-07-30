variable "setup" {
  type = map
  default = {
    environment         = "network"
    name                = "network"
    creator             = "terraform"
    account             = "123456789012"
    region		= "eu-west-1"
    service_name	= "vpn01"
    domain_name		= "network.example.com"
  }
}


