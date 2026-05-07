# ============================================================
# API GATEWAY — serverless-file-api-Axeonmedia
# ============================================================

# REST API
resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.project_name}-api"
  description = "API serverless de distribution de fichiers"
}

# ============================================================
# RESSOURCES
# ============================================================

# Ressource /fichiers
resource "aws_api_gateway_resource" "fichiers" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "fichiers"
}

# Ressource /fichiers/{file_key}
resource "aws_api_gateway_resource" "file_key" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.fichiers.id
  path_part   = "{file_key}"
}

# ============================================================
# COGNITO AUTHORIZER
# ============================================================

resource "aws_api_gateway_authorizer" "cognito" {
  name            = "cognito-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.api.id
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [var.cognito_user_pool_arn]
  identity_source = "method.request.header.Authorization"
}

# ============================================================
# MÉTHODE GET /fichiers/{file_key}
# ============================================================

resource "aws_api_gateway_method" "get_fichier" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.file_key.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

# ============================================================
# INTÉGRATION LAMBDA
# ============================================================

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.file_key.id
  http_method             = aws_api_gateway_method.get_fichier.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# ============================================================
# PERMISSION API GATEWAY → LAMBDA
# ============================================================

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# ============================================================
# DÉPLOIEMENT
# ============================================================

resource "aws_api_gateway_deployment" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_authorizer.cognito
  ]

  triggers = {
    redeploiement = sha1(jsonencode([
      aws_api_gateway_rest_api.api.body,
      aws_api_gateway_authorizer.cognito.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deploy.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.environment
}

# ============================================================
# LOGS CLOUDWATCH
# ============================================================

resource "aws_cloudwatch_log_group" "apigw" {
  name              = "/aws/api-gateway/${var.project_name}"
  retention_in_days = 30
}
