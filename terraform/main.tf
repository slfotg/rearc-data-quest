resource "aws_ssm_parameter" "foo" {
  name  = "foo"
  type  = "String"
  value = "bar"
}

module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "update_bls_data"
  handler       = "update_bls_data.update_bls_data"
  runtime       = "python3.12"

  source_path = "${path.module}../src/lambda"

  store_on_s3 = true
  s3_bucket   = module.s3_bucket.s3_bucket_id
  s3_prefix   = "lambda-builds/"

  artifacts_dir = "${path.root}/.terraform/lambda-builds/"

  layers = [
    module.lambda_layer_s3.lambda_layer_arn,
  ]

  environment_variables = {
    BUCKET_NAME = "github-slfotg-rearc-data"
    BASE_URL    = "https://download.bls.gov/pub/time.series/pr/"
    USER_AGENT  = "slfotg@gmail.com"
  }

  attach_policy_jsons = true
  policy_jsons = [
    <<-EOT
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Effect": "Allow",
                  "Action": "s3:*",
                  "Resource": "arn:aws:s3:::github-slfotg-rearc-data"
              }
          ]
      }
    EOT
  ]
  number_of_policy_jsons = 1

}

module "lambda_layer_s3" {
  source = "terraform-aws-modules/lambda/aws"

  create_layer = true

  layer_name          = "${random_pet.this.id}-layer-s3"
  description         = "update_bls_data layer"
  compatible_runtimes = ["python3.12"]

  source_path = "${path.module}../src/lambda"

  store_on_s3 = true
  s3_bucket   = module.s3_bucket.s3_bucket_id
}

resource "random_pet" "this" {
  length = 2
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket_prefix = "${random_pet.this.id}-"
  force_destroy = true

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
