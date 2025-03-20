
resource "aws_ec2_client_vpn_endpoint" "vpn_endpoint" {
  description            = "VPN 1"
  server_certificate_arn = aws_acm_certificate.vpn_cert.arn
  authentication_options {
    type         = "federated-authentication"
    saml_provider_arn = aws_iam_saml_provider.saml_provider.arn
  }
  connection_log_options {
    enabled              = true
    cloudwatch_log_group = "/aws/vpn"
  }
  dns_servers = ["8.8.8.8", "8.8.4.4"]
  client_cidr_block    = "10.98.0.0/16"
  transport_protocol   = "udp"  
  tags = {
    Name = "VPN-Full"
  }
}

resource "aws_iam_saml_provider" "saml_provider" {
  name                   = "AzureAD"
  # Update with the path to your Azure AD SAML metadata XML file
  saml_metadata_document = file("ad_saml_metadata.xml") 
}

resource "aws_ec2_client_vpn_network_association" "vpn_endpoint_assoc" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  subnet_id              = aws_subnet.private_subnet.id
}

resource "aws_ec2_client_vpn_authorization_rule" "vpn_authorization_rule" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  target_network_cidr    = "0.0.0.0/0"
  authorize_all_groups   = true
}

