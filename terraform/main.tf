locals {
  data_bucket = "github-slfotg-rearc-data"
  pr_url      = "https://download.bls.gov/pub/time.series/pr/"
  email       = "slfotg@gmail.com"
  api_url     = "https://datausa.io/api/data"
}

data "aws_caller_identity" "current" {}

module "eventbridge" {
  source = "terraform-aws-modules/eventbridge/aws"

  create_bus = true
  bus_name   = "example"

  attach_lambda_policy = true
  lambda_target_arns   = [module.lambda_function.lambda_function_arn]

  schedules = {
    lambda-cron = {
      description         = "Trigger for a Lambda"
      schedule_expression = "cron(0 21 * * ? *)"
      timezone            = "America/Chicago"
      arn                 = module.lambda_function.lambda_function_arn
      input               = jsonencode({ "job" : "cron-by-rate" })
    }
  }
}


module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "update_bls_data"
  handler       = "index.update_bls_data"
  runtime       = "python3.12"

  source_path = "${path.module}/../src/update_data"

  store_on_s3 = true
  s3_bucket   = module.s3_bucket.s3_bucket_id
  s3_prefix   = "lambda-builds/"

  artifacts_dir = "${path.root}/.terraform/lambda-builds/"

  layers = [
    module.lambda_layer_s3.lambda_layer_arn,
  ]

  environment_variables = {
    BUCKET_NAME  = local.data_bucket
    BASE_URL     = local.pr_url
    USER_AGENT   = local.email
    API_BASE_URL = local.api_url
  }

  trusted_entities = ["scheduler.amazonaws.com"]

  create_current_version_allowed_triggers = false
  allowed_triggers = {
    ScanAmiRule = {
      principal  = "scheduler.amazonaws.com"
      source_arn = module.eventbridge.eventbridge_schedule_arns["lambda-cron"]
    }
  }

  assume_role_policy_statements = {
    account_root = {
      effect  = "Allow",
      actions = ["sts:AssumeRole"],
      principals = {
        account_principal = {
          type        = "AWS",
          identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
        }
      }
    }
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
                  "Resource": [
                    "arn:aws:s3:::github-slfotg-rearc-data",
                    "arn:aws:s3:::github-slfotg-rearc-data/*"
                  ]
              }
          ]
      }
    EOT
  ]
  number_of_policy_jsons = 1

  timeout = 20
  timeouts = {
    create = "20m"
    update = "20m"
    delete = "20m"
  }
}

module "lambda_layer_s3" {
  source = "terraform-aws-modules/lambda/aws"

  create_layer = true

  layer_name          = "${random_pet.this.id}-layer-s3"
  description         = "update_bls_data layer"
  compatible_runtimes = ["python3.12"]

  source_path = "${path.module}/../src/lambda"

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
