output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "cognito_user_pool_id" {
  value = module.auth.user_pool_id
}

output "cognito_client_id" {
  value = module.auth.client_id
}

output "uploads_bucket" {
  value = module.storage.uploads_bucket_name
}

output "dynamodb_table" {
  value = module.database.table_name
}

output "sqs_queue_url" {
  value = module.queue.queue_url
}

output "backend_url" {
  value = "https://${module.backend.service_url}"
}

output "frontend_url" {
  value = "https://${module.frontend.cloudfront_url}"
}

output "cloudfront_distribution_id" {
  value = module.frontend.distribution_id
}
