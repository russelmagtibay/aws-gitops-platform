# Exports the SNS Topic ARN in case future modules want to send alerts to the same email channel
output "sns_topic_arn" {
  description = "ARN of the alerts SNS topic"
  value       = aws_sns_topic.alerts.arn
}