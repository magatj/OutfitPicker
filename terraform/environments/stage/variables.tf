variable "environment" {
  type    = string
  default = "dev"
}
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "app_name" {
  type    = string
  default = "outitpicker"
}
variable "ecr_image_uri" {
  type        = string
  description = "Full ECR image URI including tag (e.g. 123456789.dkr.ecr.us-east-1.amazonaws.com/outitpicker/backend:latest)"
}
variable "app_runner_cpu" {
  type    = string
  default = "256"
}
variable "app_runner_memory" {
  type    = string
  default = "512"
}
variable "cors_origins" {
  type    = string
  default = "http://localhost:3000"
}
