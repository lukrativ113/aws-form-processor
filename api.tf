resource "aws_api_gateway_rest_api" "api_lambda" {
  name        = "${local.name_prefix}-form-sendmail-api"
  description = "Serverless form processor API"
  
  endpoint_configuration {
      types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "proxy" {
   rest_api_id = aws_api_gateway_rest_api.api_lambda.id
   parent_id   = aws_api_gateway_rest_api.api_lambda.root_resource_id
   path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
    rest_api_id   = "${aws_api_gateway_rest_api.api_lambda.id}"
    resource_id   = "${aws_api_gateway_resource.proxy.id}"
    http_method   = "ANY"
    authorization = "NONE"
}

resource "aws_api_gateway_method_response" "options" {
    rest_api_id   = aws_api_gateway_rest_api.api_lambda.id
    resource_id   = aws_api_gateway_method.proxy.resource_id
    http_method   = "OPTIONS"
    status_code   = "200"

    response_models = {
        "application/json" = "Empty"
    }

    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = true,
        "method.response.header.Access-Control-Allow-Methods" = true,
        "method.response.header.Access-Control-Allow-Origin" = true
    }
}

resource "aws_api_gateway_integration" "options" {
    rest_api_id   = aws_api_gateway_rest_api.api_lambda.id
    resource_id   = aws_api_gateway_method.proxy.resource_id
    http_method   = "OPTIONS"
    type             = "MOCK"
    content_handling = "CONVERT_TO_TEXT"

    request_templates = {
        "application/json" = "{\"statusCode\": 200}"
    }
}

resource "aws_api_gateway_integration_response" "options" {
    rest_api_id   = aws_api_gateway_rest_api.api_lambda.id
    resource_id   = aws_api_gateway_method.proxy.resource_id
    http_method   = "OPTIONS"
    status_code   = aws_api_gateway_method_response.options.status_code

    response_templates = {
        "application/json" = ""
    }

    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
        "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
        "method.response.header.Access-Control-Allow-Origin" = "'*'"
    }
}

resource "aws_api_gateway_integration" "lambda" {
    rest_api_id      = aws_api_gateway_rest_api.api_lambda.id
    resource_id      = aws_api_gateway_method.proxy.resource_id
    http_method      = aws_api_gateway_method.proxy.http_method

    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = aws_lambda_function.ses_function.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
   rest_api_id   = aws_api_gateway_rest_api.api_lambda.id
   resource_id   = aws_api_gateway_rest_api.api_lambda.root_resource_id
   http_method   = "ANY"
   authorization = "NONE"
}

resource "aws_api_gateway_method_response" "options_root" {
    rest_api_id   = aws_api_gateway_rest_api.api_lambda.id
    resource_id   = aws_api_gateway_method.proxy_root.resource_id
    http_method   = "OPTIONS"
    status_code   = "200"

    response_models = {
        "application/json" = "Empty"
    }

    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = true,
        "method.response.header.Access-Control-Allow-Methods" = true,
        "method.response.header.Access-Control-Allow-Origin" = true
    }
}

resource "aws_api_gateway_integration" "options_root" {
    rest_api_id   = aws_api_gateway_rest_api.api_lambda.id
    resource_id   = aws_api_gateway_method.proxy_root.resource_id
    http_method   = "OPTIONS"
    type             = "MOCK"
    content_handling = "CONVERT_TO_TEXT"

    request_templates = {
        "application/json" = "{\"statusCode\": 200}"
    }
}

resource "aws_api_gateway_integration_response" "options_root" {
    rest_api_id   = aws_api_gateway_rest_api.api_lambda.id
    resource_id   = aws_api_gateway_method.proxy_root.resource_id
    http_method   = "OPTIONS"
    status_code   = aws_api_gateway_method_response.options_root.status_code

    response_templates = {
        "application/json" = ""
    }

    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
        "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
        "method.response.header.Access-Control-Allow-Origin" = "'*'"
    }
}

resource "aws_api_gateway_integration" "lambda_root" {
   rest_api_id = aws_api_gateway_rest_api.api_lambda.id
   resource_id = aws_api_gateway_method.proxy_root.resource_id
   http_method = aws_api_gateway_method.proxy_root.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.ses_function.invoke_arn
}

resource "aws_api_gateway_deployment" "api_lambda" {
   depends_on = [
     "aws_api_gateway_integration.lambda",
     "aws_api_gateway_integration.lambda_root",
   ]

   rest_api_id = aws_api_gateway_rest_api.api_lambda.id
   stage_name  = var.environ
}


resource "aws_lambda_permission" "apigw" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.ses_function.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.api_lambda.execution_arn}/*/*"
}


output "base_url" {
  value = aws_api_gateway_deployment.api_lambda.invoke_url
}
