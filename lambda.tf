data "archive_file" "lambda_payload" {
  type        = "zip"
  source_file = "${path.module}/src/awslambda/email_function.py"
  output_path = "${path.module}/payload.zip"
}

resource "aws_lambda_function" "ses_function" {
  filename         = data.archive_file.lambda_payload.output_path
  function_name    = "${local.name_prefix}-form-sendmail"
  role             = aws_iam_role.ses_function_role.arn
  handler          = "email_function.lambda_handler"

  source_code_hash = data.archive_file.lambda_payload.output_base64sha256

  runtime = "python3.7"

  environment {
    variables = {
      SENDER_EMAIL = var.valid_sender
      TO_EMAIL = var.valid_sender
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.ses_function_attach
  ]
}