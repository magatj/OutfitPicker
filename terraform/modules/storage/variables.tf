variable "app_name" { type = string }
variable "environment" { type = string }
variable "cors_origins" {
  type    = list(string)
  default = ["*"]
}
