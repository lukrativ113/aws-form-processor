resource "aws_iam_role" "ses_function_role" {
  name = "${local.name_prefix}-lambda-form-sendmail"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "ses_function_policy" {
  name        = "${local.name_prefix}-lambda-form-sendmail-perm"
  description = "SES Sendmail perms for form processor lambda function"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ses:SendEmail"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ses_function_attach" {
  role       = aws_iam_role.ses_function_role.name
  policy_arn = aws_iam_policy.ses_function_policy.arn
}