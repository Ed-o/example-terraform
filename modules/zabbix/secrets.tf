data "aws_secretsmanager_secret_version" "creds" {
  # Get it from AWS secrets
  secret_id = "zabbix"
}

locals {
  # Set the secrets from AWS Secrets Manager
  ec2_creds = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)

}

