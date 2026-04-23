terraform {
  backend "s3" {
    bucket         = "outitpicker-tf-state"
    key            = "stage/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "outitpicker-tf-locks"
    encrypt        = true
  }
}
