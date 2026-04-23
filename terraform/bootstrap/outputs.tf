output "tf_state_bucket" {
  value = aws_s3_bucket.tf_state.id
}

output "tf_lock_table" {
  value = aws_dynamodb_table.tf_locks.name
}
