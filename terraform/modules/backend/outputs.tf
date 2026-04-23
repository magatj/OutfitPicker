output "service_url" {
  value = aws_apprunner_service.backend.service_url
}

output "service_arn" {
  value = aws_apprunner_service.backend.arn
}
