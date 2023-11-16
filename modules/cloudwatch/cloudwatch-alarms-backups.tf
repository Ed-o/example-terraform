### AWS-Backup Alarms :

resource "aws_cloudwatch_metric_alarm" "backups_jobfail_alarm" {
  count = var.backups.backup01.enabled ? 1 : 0
  alarm_name          = "Backup-BackupJob-Fail"
  alarm_description   = "Alarm when a backup job fails"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfBackupJobsFailed"
  namespace           = "AWS/Backup"
  period              = "86400"
  statistic           = "Sum"
  threshold           = "0"
  actions_enabled     = true
  alarm_actions       = [ aws_sns_topic.alert_topic["low"].arn ]
  #dimensions = {
  #  BackupVaultName = "product-backup-vault"
  #}
}

resource "aws_cloudwatch_metric_alarm" "backups_copyfail_alarm" {
  count = var.backups.backup01.enabled ? 1 : 0
  alarm_name          = "Backup-copyJob-Fail"
  alarm_description   = "Alarm when a backup copy fails"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfCopyJobsFailed"
  namespace           = "AWS/Backup"
  period              = "86400"
  statistic           = "Sum"
  threshold           = "0"
  actions_enabled     = true
  alarm_actions       = [ aws_sns_topic.alert_topic["low"].arn ]
  #dimensions = {
  #  BackupVaultName = "product-backup-vault"
  #}
}

