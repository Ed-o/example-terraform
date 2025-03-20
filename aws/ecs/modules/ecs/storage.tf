# Volumes to be used in the ECS system for this enviroenment

### MySQL Database

resource "aws_efs_file_system" "vol_database" {
  count = var.storage.efs_database_enable ? 1 : 0
  creation_token = "vol-db-${var.setup.name}"
  encrypted = true
  tags = {
    Name = "vol-db-${var.setup.name}"
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "database"
  }
}

resource "aws_efs_mount_target" "vol_database_mount_target" {
  count = var.storage.efs_database_enable ? length(local.subnet_private) : 0
  file_system_id  = aws_efs_file_system.vol_database[0].id
  subnet_id       = local.subnet_private[count.index]
  security_groups = [data.aws_security_group.ecs-pods.id, data.aws_security_group.product_sg_db.id]
}

resource "aws_efs_access_point" "vol_database" {
  count = var.storage.efs_database_enable ? 1 : 0
  file_system_id = aws_efs_file_system.vol_database[0].id
}



### Images EFS drive

resource "aws_efs_file_system" "vol_images" {
  count = var.storage.efs_images_enable ? 1 : 0
  creation_token = "vol-img-${var.setup.name}"
  encrypted = true
  lifecycle_policy {
    transition_to_ia = "${var.storage.efs_images_movecold}" 
  }
  throughput_mode = "bursting"
  tags = {
    Name = "vol-img-${var.setup.name}"
    environment = var.setup.environment
    creator = var.setup.creator
    asset = "volumes"
  }
}

resource "aws_efs_mount_target" "vol_images_mount_target" {
  count = var.storage.efs_images_enable ? length(local.subnet_private) : 0
  file_system_id  = aws_efs_file_system.vol_images[0].id
  subnet_id       = local.subnet_private[count.index]
  security_groups = [data.aws_security_group.ecs-pods.id]
  lifecycle {
    ignore_changes = [security_groups]
  }
}

resource "aws_efs_access_point" "vol_images" {
  count = var.storage.efs_images_enable ? 1 : 0
  file_system_id = aws_efs_file_system.vol_images[0].id
}



