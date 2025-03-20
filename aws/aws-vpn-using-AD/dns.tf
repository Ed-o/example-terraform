resource "aws_route53_zone" "dnszone" {
  name = var.setup.domain_name
}

resource "aws_acm_certificate" "vpn_cert" {
  domain_name       = "${var.setup.service_name}.${var.setup.domain_name}"
  validation_method = "DNS"

  tags = {
    Name = "VPN Certificate"
  }
}

resource "aws_route53_record" "cert_validation" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.vpn_cert.domain_validation_options)[0].resource_record_name
  records         = [ tolist(aws_acm_certificate.vpn_cert.domain_validation_options)[0].resource_record_value ]
  type            = tolist(aws_acm_certificate.vpn_cert.domain_validation_options)[0].resource_record_type
  zone_id  = aws_route53_zone.dnszone.id
  ttl      = 60
}

# This tells terraform to cause the route53 validation to happen
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.vpn_cert.arn
  validation_record_fqdns = [ aws_route53_record.cert_validation.fqdn ]
}

resource "aws_route53_record" "vpn_cert_rec" {
  zone_id = aws_route53_zone.dnszone.zone_id
  name    = "${var.setup.service_name}.${var.setup.domain_name}"
  type    = "A"
  ttl	  = 360
  records = [ aws_eip.vpn_eip.public_ip ]
}


