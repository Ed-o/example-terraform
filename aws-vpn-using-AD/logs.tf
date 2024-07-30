resource "aws_cloudwatch_log_group" "vpn_logs" {
  name = "/aws/vpn"

  tags = {
  }
}
