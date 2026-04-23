resource "aws_apprunner_service" "backend" {
  service_name = "${var.app_name}-backend-${var.environment}"

  source_configuration {
    image_repository {
      image_configuration {
        port = "8000"
        runtime_environment_variables = {
          ENVIRONMENT          = var.environment
          DYNAMODB_TABLE       = var.table_name
          UPLOADS_BUCKET       = var.uploads_bucket
          SQS_DETECTION_QUEUE  = var.queue_url
          COGNITO_USER_POOL_ID = var.cognito_pool_id
          AWS_REGION           = var.aws_region
          CORS_ORIGINS         = var.cors_origins
        }
      }
      image_identifier      = var.ecr_image_uri
      image_repository_type = "ECR"
    }
    authentication_configuration {
      access_role_arn = var.app_runner_access_role_arn
    }
    auto_deployments_enabled = true
  }

  instance_configuration {
    cpu               = var.cpu
    memory            = var.memory
    instance_role_arn = var.app_runner_role_arn
  }

  health_check_configuration {
    protocol = "HTTP"
    path     = "/health"
    interval = 10
    timeout  = 5
  }
}
