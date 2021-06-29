resource "aws_api_gateway_rest_api" "apiLambda" {
  name        = "${local.name_prefix}-form-sendmail-api"
  
  endpoint_configuration {
      types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "contact" {
   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   parent_id   = aws_api_gateway_rest_api.apiLambda.root_resource_id
   path_part   = "contact"
}

resource "aws_api_gateway_method" "contactOptionsMethod" {
    rest_api_id   = "${aws_api_gateway_rest_api.apiLambda.id}"
    resource_id   = "${aws_api_gateway_resource.contact.id}"
    http_method   = "OPTIONS"
    authorization = "NONE"
}

resource "aws_api_gateway_method_response" "contactOptions200" {
    rest_api_id   = aws_api_gateway_rest_api.apiLambda.id
    resource_id   = aws_api_gateway_resource.contact.id
    http_method   = aws_api_gateway_method.contactOptionsMethod.http_method
    status_code   = "200"

    response_models = {
        "application/json" = "Empty"
    }

    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = true,
        "method.response.header.Access-Control-Allow-Methods" = true,
        "method.response.header.Access-Control-Allow-Origin" = true
    }
    depends_on = [aws_api_gateway_method.contactOptionsMethod]
}

resource "aws_api_gateway_integration" "contactOptionsIntegration" {
    rest_api_id      = aws_api_gateway_rest_api.apiLambda.id
    resource_id      = aws_api_gateway_resource.contact.id
    http_method      = aws_api_gateway_method.contactOptionsMethod.http_method
    type             = "MOCK"
    content_handling = "CONVERT_TO_TEXT"

    request_templates = {
        "application/json" = "{\"statusCode\": 200}"
    }

    depends_on = [aws_api_gateway_method.contactOptionsMethod]
}

resource "aws_api_gateway_integration_response" "contactOptionsIntegrationResponse" {
    rest_api_id   = aws_api_gateway_rest_api.apiLambda.id
    resource_id   = aws_api_gateway_resource.contact.id
    http_method   = aws_api_gateway_method.contactOptionsMethod.http_method
    status_code   = aws_api_gateway_method_response.contactOptions200.status_code

    response_templates = {
        "application/json" = ""
    }

    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
        "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
        "method.response.header.Access-Control-Allow-Origin" = "'*'"
    }

    depends_on = [aws_api_gateway_method_response.contactOptions200]
}

resource "aws_api_gateway_method" "contactPostMethod" {
   rest_api_id   = aws_api_gateway_rest_api.apiLambda.id
   resource_id   = aws_api_gateway_resource.contact.id
   http_method   = "POST"
   authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   resource_id = aws_api_gateway_method.contactPostMethod.resource_id
   http_method = aws_api_gateway_method.contactPostMethod.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.ses_function.invoke_arn
}

resource "aws_api_gateway_deployment" "apideploy" {
   depends_on = [
     aws_api_gateway_integration.lambda
   ]

   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   stage_name  = var.environ
}


resource "aws_lambda_permission" "apigw" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.ses_function.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.apiLambda.execution_arn}/*/*"
}


output "base_url" {
  value = aws_api_gateway_deployment.apideploy.invoke_url
}