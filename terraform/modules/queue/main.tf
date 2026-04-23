resource "aws_sqs_queue" "detection_dlq" {
  name                      = "${var.app_name}-${var.environment}-detection-dlq"
  message_retention_seconds = 1209600 # 14 days
}

resource "aws_sqs_queue" "detection" {
  name                       = "${var.app_name}-${var.environment}-clothing-detection"
  visibility_timeout_seconds = 130
  message_retention_seconds  = 86400

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.detection_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue_policy" "detection" {
  queue_url = aws_sqs_queue.detection.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = var.app_runner_role_arn }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.detection.arn
    }]
  })
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "detect_clothing" {
  function_name    = "${var.app_name}-${var.environment}-detect-clothing"
  role             = var.lambda_role_arn
  runtime          = "python3.12"
  handler          = "detect_clothing.handler"
  timeout          = 120
  memory_size      = 512
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = var.table_name
      UPLOADS_BUCKET = var.uploads_bucket
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.detect_clothing.function_name}"
  retention_in_days = 14
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.detection.arn
  function_name    = aws_lambda_function.detect_clothing.arn
  batch_size       = 1
}
