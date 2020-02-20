variable bucket {}
variable sharp_source {}
variable sharp_key {}
variable lambda_runtime {}

resource aws_s3_bucket bucket {
  bucket = var.bucket
  acl    = "private"

  force_destroy = true
}

output bucket {
  value = aws_s3_bucket.bucket
}

#
# sharp lambda layer
#

resource aws_s3_bucket_object sharp {
  bucket = aws_s3_bucket.bucket.id
  key    = var.sharp_key
  source = var.sharp_source
  etag   = filemd5(var.sharp_source)
}

resource aws_lambda_layer_version sharp_layer {
  layer_name          = "sharp"
  s3_bucket           = aws_s3_bucket.bucket.id
  s3_key              = aws_s3_bucket_object.sharp.id
  compatible_runtimes = [var.lambda_runtime]
}

output sharp_layer_arn {
  value = aws_lambda_layer_version.sharp_layer.arn
}

