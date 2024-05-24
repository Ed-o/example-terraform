# ECS Cluster (Including logs etc)

resource "aws_kms_key" "log_encryption_key" {
  count = var.network_settings.shared_network == "false" ? 1 : 0
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

data "aws_kms_key" "log_encryption_key" {
    key_id = var.network_settings.shared_network ? var.network_settings.log_encryption_key : aws_kms_key.log_encryption_key[0].id
}

resource "aws_iam_role" "log_encryption_role" {
  count = var.network_settings.shared_network == "false" ? 1 : 0
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

data "aws_iam_role" "log_encryption_role" {
    name = var.network_settings.shared_network ? var.network_settings.log_encryption_role : aws_iam_role.log_encryption_role[0].name
}

