# We need a Fixed IP

resource "aws_eip" "vpn_eip" {
  domain = "vpc"
  tags = {
    Name = "EIP-VPN01"
  }
}

output "vpn_eip" {
  value = aws_eip.vpn_eip.public_ip
}

