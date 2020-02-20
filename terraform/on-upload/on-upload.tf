variable project_name {}
variable region {}
variable runtime {}
variable source_file {}
variable output_path {}
variable lambda_role_arn {}
variable bucket {}
variable state_machine_arn {}

locals {
  lambda_name = "on-upload"
}

#
# bucket event notification
#

resource aws_s3_bucket_notification bucket_upload_notification {
  bucket = var.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
  }
}

#
# lambda permissions
#

resource aws_lambda_permission upload_permission {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.bucket.arn
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

  environment {
    variables = {
      STATE_MACHINE_ARN = var.state_machine_arn,
      REGION            = var.region
    }
  }
}

output function_name {
  value = aws_lambda_function.lambda_function.function_name
}

output lambda_function_arn {
  value = aws_lambda_function.lambda_function.arn
}