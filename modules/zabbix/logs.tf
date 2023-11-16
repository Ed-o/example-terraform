resource "aws_kms_key" "log_encryption_key" {
  description = "KMS Key for encrypting ECS logs"
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "kms_key"
  }
  policy = <<EOF
{
  "Version" : "2012-10-17",
  "Id" : "key-default-1",
  "Statement" : [ {
      "Sid" : "Enable IAM User Permissions",
      "Effect" : "Allow",
      "Principal" : {
        "AWS" : "arn:aws:iam::${var.setup.account}:root"
      },
      "Action" : "kms:*",
      "Resource" : "*"
    },
    {
      "Effect": "Allow",
      "Principal": { "Service": "logs.${var.network_settings.region}.amazonaws.com" },
      "Action": [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "log_encryption_role" {
  name = "log_encryption_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "logs.${var.network_settings.region}.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "zabbix_ecs" {
  name = "zabbix-ecs"
  retention_in_days = 7
  kms_key_id = aws_kms_key.log_encryption_key.arn
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "ecs-cluster"
  }
}

resource "aws_cloudwatch_log_stream" "zabbix_ecs_log_stream" {
  name           = "zabbix-logs"
  log_group_name = aws_cloudwatch_log_group.zabbix_ecs.name
}

resource "aws_cloudwatch_log_group" "zabbix_cloudwatch" {
  name = "zabbix-logs"
  retention_in_days = 7
  kms_key_id = aws_kms_key.log_encryption_key.arn
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "zabbix"
  }
}


