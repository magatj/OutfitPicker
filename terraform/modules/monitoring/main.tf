resource "aws_cloudwatch_log_group" "app_runner" {
  name              = "/aws/apprunner/${var.app_name}-backend-${var.environment}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_metric_alarm" "backend_5xx" {
  alarm_name          = "${var.app_name}-${var.environment}-backend-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5xxError"
  namespace           = "AWS/AppRunner"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Backend returning too many 5xx errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ServiceName = "${var.app_name}-backend-${var.environment}"
  }
}

resource "aws_cloudwatch_metric_alarm" "dlq_depth" {
  alarm_name          = "${var.app_name}-${var.environment}-dlq-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Messages in DLQ — detection jobs are failing"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = var.dlq_name
  }
}
