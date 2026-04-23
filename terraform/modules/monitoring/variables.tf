variable "app_name" { type = string }
variable "environment" { type = string }
variable "dlq_name" { type = string }
variable "log_retention_days" {
  type    = number
  default = 14
}
