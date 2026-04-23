output "queue_url" {
  value = aws_sqs_queue.detection.url
}

output "queue_arn" {
  value = aws_sqs_queue.detection.arn
}

output "dlq_arn" {
  value = aws_sqs_queue.detection_dlq.arn
}
