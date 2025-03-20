# Create a CloudWatch dashboard

# Get the ARN of the ALB by name
#data "aws_lb" "alb" {
#  name = var.network_settings.alb_name
#}

### Now make the Graphs :

resource "aws_cloudwatch_dashboard" "cloudwatch_servers" {
  dashboard_name = "cloudwatch_servers"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x    = 0
        y    = 0
        width = 12
        height = 6
        properties = {
          view  = "timeSeries"
          title = "Load Balancer"
          stacked = false
          metrics = [
            [ { "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"RequestCount\" ', 'Sum', 300)" } ],
            [ { "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_ELB_2XX_Count\" ', 'Sum', 300)" } ],
            [ { "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_ELB_3XX_Count\" ', 'Sum', 300)" } ],
            [ { "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_ELB_4XX_Count\" ', 'Sum', 300)" } ],
            [ { "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_ELB_5XX_Count\" ', 'Sum', 300)" } ]
          ]
          period = 300
          region = var.network_settings.region
        }
      },
      {
        type = "metric"
        x    = 0
        y    = 6
        width = 12
        height = 6
        properties = {
          view  = "timeSeries"
          title = "EC2 Servers - CPU"
          stacked = false
          metrics = [
            [ { "expression": "SEARCH('{AWS/EC2,InstanceId} MetricName=\"CPUUtilization\"', 'Average', 300)", "id": "e1" } ]
          ]
          labels = [
            {
              "key": "State",
              "value": "running"
             }
          ]
          period = 300
          region = var.network_settings.region
        }
      },
      {
        type = "metric"
        x = 0
        y = 12
        width = 12
        height = 6
        properties = {
          metrics = [
            [ { "expression": "SEARCH('{AWS/RDS,DBInstanceIdentifier} MetricName=\"CPUUtilization\"', 'Average', 300)", "id": "e1" } ],
            [ { "expression": "SEARCH('{AWS/RDS,DBInstanceIdentifier} MetricName=\"DatabaseConnections\"', 'Average', 300)", "id": "e2", "yAxis": "right" } ]
          ]
          view = "timeSeries"
          stacked = false
          region = "${var.network_settings.region}"
          title = "RDS Metrics"
        }
      },
      {
        type = "metric"
        x    = 0
        y    = 6
        width = 12
        height = 6
        properties = {
          view  = "timeSeries"
          title = "Reddis"
          stacked = false
          metrics = [
            [ { "expression": "SEARCH('{AWS/ElastiCache,CacheClusterId} MetricName=\"CPUUtilization\"', 'Average', 300)", "id": "e1" } ],
            [ { "expression": "SEARCH('{AWS/ElastiCache,CacheClusterId} MetricName=\"FreeableMemory\"', 'Average', 300)", "id": "e2", "yAxis": "right" } ]
          ]
          labels = [
            {
              "key": "State",
              "value": "running"
             }
          ]
          period = 300
          region = var.network_settings.region
        }
      }
    ]
  })
}




