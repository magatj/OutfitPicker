output "app_runner_role_arn" {
  value = aws_iam_role.app_runner.arn
}

output "app_runner_access_role_arn" {
  value = aws_iam_role.app_runner_access.arn
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda.arn
}
