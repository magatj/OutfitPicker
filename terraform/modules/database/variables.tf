variable "app_name" { type = string }
variable "environment" { type = string }
variable "enable_pitr" {
  type    = bool
  default = false
}
variable "enable_deletion_protection" {
  type    = bool
  default = false
}
