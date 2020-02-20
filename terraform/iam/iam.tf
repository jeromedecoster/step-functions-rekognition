variable project_name {}

#
# lambda assume role policy
#

# trust relationships
data aws_iam_policy_document lambda_assume_role_policy {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource aws_iam_role lambda_role {
  name               = "${var.project_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

output lambda_role_arn {
  value = aws_iam_role.lambda_role.arn
}

#
# lambda policy
#

# inline policy data
data aws_iam_policy_document lambda_policy {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:DeleteObject",
      "rekognition:*",
      "states:StartExecution",
      "dynamodb:*"
    ]
    resources = ["*"]
  }
}

# add inline policy to lambda_role
resource aws_iam_role_policy lambda_policy {
  name   = "${var.project_name}-lambda-policy"
  policy = data.aws_iam_policy_document.lambda_policy.json
  role   = aws_iam_role.lambda_role.name
}
