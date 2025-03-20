resource "aws_iam_role" "ecs_task_role" {
  count = ((var.network_settings.shared_network == "false") && (var.network_settings.ecs_task_role == "")) ? 1 : 0
  name = "ecs_task_role"
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "iam"
  }
  assume_role_policy = <<EOF1
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF1
}

data "aws_iam_role" "ecs_task_role" {
    name = var.network_settings.ecs_task_role != "" ? var.network_settings.ecs_task_role : aws_iam_role.ecs_task_role[0].name
}

resource "aws_iam_role" "ecs_exec_role" {
  count = ((var.network_settings.shared_network == "false") && (var.network_settings.ecs_exec_role == "")) ? 1 : 0
  name = "ecs_exec_role"
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "iam"
  }
  assume_role_policy = <<EOF2
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF2
}

data "aws_iam_role" "ecs_exec_role" {
    name = var.network_settings.ecs_exec_role != "" ? var.network_settings.ecs_exec_role : aws_iam_role.ecs_exec_role[0].name
}

resource "aws_iam_policy" "ecs_task_policy" {
  count = ((var.network_settings.shared_network == "false") && (var.network_settings.ecs_task_role == "")) ? 1 : 0
  name = "ecs_task_policy"
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "iam"
  }
  policy = <<EOF3
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateTaskSet",
        "ecs:DeregisterTaskDefinition",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeTasks",
        "ecs:ListTasks",
        "ecs:RegisterTaskDefinition",
        "ecs:ExecuteCommand",
        "ecs:RunTask",
        "ecs:StopTask"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:DescribeInstanceHealth",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
	"ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ],
      "Resource": "*",
      "Condition": {
        "ArnLike": {
          "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:${var.network_settings.region}:${var.setup.account}:log-group:SSM"
        }
      }
    },    
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ],
      "Resource": "*"            
    }, 
    {
      "Effect": "Allow",    
      "Action": [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
         "s3:PutObject",
         "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::product-reporting-*/*",
        "arn:aws:s3:::dbimport-*/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
         "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
EOF3
}

resource "aws_iam_policy" "ecs_exec_policy" {
  count = ((var.network_settings.shared_network == "false") && (var.network_settings.ecs_exec_role == "")) ? 1 : 0
  name = "ecs_exec_policy"
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "iam"
  }
  policy = <<EOF4
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
       "Action": [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
       ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
       "Action": [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage"
       ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
       "Action": [
            "efs:DescribeMountTargets",
            "efs:MountTarget*",
            "efs:ClientMount"
       ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF4
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy_attachment" {
  count = ((var.network_settings.shared_network == "false") && (var.network_settings.ecs_task_role == "")) ? 1 : 0
  role = aws_iam_role.ecs_task_role[0].name
  policy_arn = aws_iam_policy.ecs_task_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy_attachment" {
  count = ((var.network_settings.shared_network == "false") && (var.network_settings.ecs_exec_role == "")) ? 1 : 0
  role = aws_iam_role.ecs_task_role[0].name
  # role = aws_iam_role.ecs_exec_role.name     ### <--- Taken out as the exec role was not working so put both in task role
  policy_arn = aws_iam_policy.ecs_exec_policy[0].arn
}

### And this part allows for this account to get its ECR downloads from the account that has it 

resource "aws_iam_policy" "ecr_cross_account_policy" {
  count = ((var.network_settings.shared_network == "false") && (var.network_settings.ecs_task_role == "")) ? 1 : 0
  name = "ecr-cross-account-access-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
        ]
        Resource = "arn:aws:ecr:eu-west-1:987654321:repository/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_cross_account_policy_attachment" {
  count = ((var.network_settings.shared_network == "false") && (var.network_settings.ecs_task_role == "")) ? 1 : 0
  policy_arn = aws_iam_policy.ecr_cross_account_policy[0].arn
  role = aws_iam_role.ecs_task_role[0].name
}


