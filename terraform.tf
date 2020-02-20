locals {
  project_name   = "step-functions-rekognition-${random_id.random.hex}"
  region         = "eu-west-1"
  lambda_runtime = "nodejs12.x"

  # module s3
  bucket = local.project_name
}

provider aws {
  region = local.region
}

resource random_id random {
  byte_length = 3
}

#
# modules
#

module s3 {
  source         = "./terraform/s3"
  bucket         = local.bucket
  sharp_source   = "./layers/sharp-0.24.1.zip"
  sharp_key      = "layers/sharp-0.24.1.zip"
  lambda_runtime = local.lambda_runtime
}

module on_upload {
  source            = "./terraform/on-upload"
  project_name      = local.project_name
  region            = local.region
  bucket            = module.s3.bucket
  runtime           = local.lambda_runtime
  source_file       = "./lambdas/on-upload.js"
  output_path       = "./lambdas/zip/on-upload.zip"
  lambda_role_arn   = module.iam.lambda_role_arn
  state_machine_arn = module.state_machine.state_machine_arn
}

module detect_faces {
  source              = "./terraform/detect-faces"
  project_name        = local.project_name
  runtime             = local.lambda_runtime
  source_file         = "./lambdas/detect-faces.js"
  output_path         = "./lambdas/zip/detect-faces.zip"
  lambda_role_arn     = module.iam.lambda_role_arn
  dynamodb_table_name = module.dynamodb.table_name
}

module no_face_detected {
  source          = "./terraform/no-face-detected"
  project_name    = local.project_name
  runtime         = local.lambda_runtime
  source_file     = "./lambdas/no-face-detected.js"
  output_path     = "./lambdas/zip/no-face-detected.zip"
  lambda_role_arn = module.iam.lambda_role_arn
}

module add_to_collection {
  source              = "./terraform/add-to-collection"
  project_name        = local.project_name
  region              = local.region
  runtime             = local.lambda_runtime
  source_file         = "./lambdas/add-to-collection.js"
  output_path         = "./lambdas/zip/add-to-collection.zip"
  lambda_role_arn     = module.iam.lambda_role_arn
  dynamodb_table_name = module.dynamodb.table_name
}

module thumbnail {
  source          = "./terraform/thumbnail"
  project_name    = local.project_name
  region          = local.region
  runtime         = local.lambda_runtime
  source_file     = "./lambdas/thumbnail.js"
  output_path     = "./lambdas/zip/thumbnail.zip"
  lambda_role_arn = module.iam.lambda_role_arn
  sharp_layer_arn = module.s3.sharp_layer_arn
}

module iam {
  source       = "./terraform/iam"
  project_name = local.project_name
}

module state_machine {
  source                         = "./terraform/state-machine"
  project_name                   = local.project_name
  detect_faces_function_arn      = module.detect_faces.function_arn
  no_face_detected_function_arn  = module.no_face_detected.function_arn
  add_to_collection_function_arn = module.add_to_collection.function_arn
  thumbnail_function_arn         = module.thumbnail.function_arn
}

module dynamodb {
  source       = "./terraform/dynamodb"
  project_name = local.project_name
}

#
# outputs
#

output project_name {
  value = local.project_name
}

output region {
  value = local.region
}

output bucket {
  value = local.bucket
}

output on_upload_function {
  value = module.on_upload.function_name
}