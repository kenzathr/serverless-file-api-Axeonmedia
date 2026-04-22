# Packager le code dans un zip
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "presign" {
  function_name    = "${var.project_name}-presign"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  handler          = "handler.handler"
  runtime          = "python3.11"
  role             = var.lambda_role_arn
  timeout          = 10
  memory_size      = 128

 environment {
    variables = {
      BUCKET_NAME        = var.bucket_id
      DYNAMODB_TABLE     = var.dynamodb_table_name
      URL_EXPIRY         = "3600" # On enlève _SECONDS pour matcher le code Python
    }
  }

  tags = {
    Projet        = var.project_name
    Environnement = var.environment
  }
}

# Log group CloudWatch pour la Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.presign.function_name}"
  retention_in_days = 30
}
