# ECS Cluster

resource "aws_cloudwatch_log_group" "product_ecs" {
  name = "ecs-${var.setup.name}"
  retention_in_days = 7
  kms_key_id = data.aws_kms_key.log_encryption_key.arn
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "ecs-cluster"
  }
}

resource "aws_cloudwatch_log_stream" "product_ecs_log_stream" {
  name           = "ecs-tasks-${var.setup.name}"
  log_group_name = aws_cloudwatch_log_group.product_ecs.name
}

resource "aws_ecs_cluster" "product" {
  name = "product-${var.setup.name}"

  configuration {
    execute_command_configuration {
      kms_key_id = data.aws_kms_key.log_encryption_key.arn
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.product_ecs.name
      }
    }
  }
  tags = {
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "ecs-cluster"
  }
  depends_on = [aws_cloudwatch_log_stream.product_ecs_log_stream]
}


