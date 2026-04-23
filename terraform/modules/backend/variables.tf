variable "app_name" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string  default = "us-east-1" }
variable "ecr_image_uri" { type = string }
variable "cpu" { type = string  default = "256" }
variable "memory" { type = string  default = "512" }
variable "app_runner_role_arn" { type = string }
variable "app_runner_access_role_arn" { type = string }
variable "table_name" { type = string }
variable "uploads_bucket" { type = string }
variable "queue_url" { type = string }
variable "cognito_pool_id" { type = string }
variable "cors_origins" { type = string  default = "*" }
