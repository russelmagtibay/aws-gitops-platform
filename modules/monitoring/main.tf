# ---------------------------------------------------------------------------
# RESOURCE 1: SNS Topic (The Megaphone / Notification Channel)
# CloudWatch Alarms cannot send emails directly! They send a message to an
# SNS Topic, and the SNS Topic forwards that message to your email.
# ---------------------------------------------------------------------------


resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"

  kms_master_key_id = "alias/aws/sns"
}

# Connects your email address to the SNS Topic megaphone
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ---------------------------------------------------------------------------
# RESOURCE 2: CloudWatch Alarm for High Container CPU (> 80% for 2 minutes)
# Watches AWS/ECS CPUUtilization for our specific ClusterName and ServiceName.
# ---------------------------------------------------------------------------


resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-ecs-high-cpu"
  comparison_operator = "GreaterThanThreshold"

  evaluation_periods = 2  #will check the cpu 2 times
  period             = 60 #wil check every 60 seconds
  metric_name        = "CPUUtilization"
  threshold          = 80 # 80% CPU threshold

  namespace = "AWS/ECS"
  statistic = "Average"

  treat_missing_data = "notBreaching" # Don't alarm if there is no data

  alarm_actions = [aws_sns_topic.alerts.arn]

  # Filters the metric to ONLY watch our specific ECS cluster & service

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

}


# ---------------------------------------------------------------------------
# RESOURCE 3: CloudWatch Alarm for Application Crashing (HTTP 5xx > 5/min)
# Watches the Load Balancer to see if our Python containers return 500 errors.
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum" # Count total 5xx errors in 60 seconds
  threshold           = 5     # More than 5 errors in 1 minute
  treat_missing_data  = "notBreaching"
  alarm_description   = "Triggers when backend containers return more than 5 HTTP 5xx errors/min"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}
# ---------------------------------------------------------------------------
# RESOURCE 4: AWS Cost Budget ($10/month cap to protect your AWS credits!)
# Emails you immediately if your actual monthly bill exceeds 80% of $10 ($8).
# ---------------------------------------------------------------------------
resource "aws_budgets_budget" "monthly" {
  name         = "${var.project_name}-monthly-budget"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd) # Converts number 10 -> string "10"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80 # Alert at 80% of budget ($8.00)
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
  lifecycle {
    precondition {
      condition     = var.monthly_budget_usd <= 100
      error_message = "Monthly budget limit cannot exceed your Free Tier credit balance ($100)."
    }
  }
}