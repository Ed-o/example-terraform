resource "aws_route53_record" "route53" {
  count = "${var.network_settings.dns_enabled == "false" ? 0 : 1}"
  zone_id = "${var.network_settings.dns_zone}"
  name = "${var.setup.domain}"
  type = "A"

  alias {
    name = "${aws_alb.alb.dns_name}"
    zone_id = "${aws_alb.alb.zone_id}"
    evaluate_target_health = false
  }
}
