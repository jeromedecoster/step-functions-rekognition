variable project_name {}
variable runtime {}
variable source_file {}
variable output_path {}
variable lambda_role_arn {}

locals {
  lambda_name = "no-face-detected"
}

#
# lambda function
#

data archive_file zip {
  type        = "zip"
  source_file = var.source_file
  output_path = var.output_path
}

resource aws_lambda_function lambda_function {
  filename         = data.archive_file.zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.zip.output_path)

  function_name = "${var.project_name}-${local.lambda_name}"
  role          = var.lambda_role_arn
  handler       = "${local.lambda_name}.handler"
  runtime       = var.runtime
  timeout       = 10
}

output function_name {
  value = aws_lambda_function.lambda_function.function_name
}

output function_arn {
  value = aws_lambda_function.lambda_function.arn
}