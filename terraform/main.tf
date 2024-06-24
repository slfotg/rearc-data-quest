locals {
  data_bucket = "github-slfotg-rearc-data"
  pr_url      = "https://download.bls.gov/pub/time.series/pr/"
  email       = "slfotg@gmail.com"
  api_url     = "https://datausa.io/api/data"
  runtime     = "python3.12"
}

data "aws_caller_identity" "current" {}

data "aws_s3_bucket" "data_bucket" {
  bucket = local.data_bucket
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

module "update_data" {
  source = "./update_data"

  function_name = "update_data"
  handler       = "index.update_data"
  runtime       = local.runtime

  data_bucket    = data.aws_s3_bucket.data_bucket.id
  account_id     = data.aws_caller_identity.current.account_id
  lambda_source  = "${path.module}/../src/update_data"
  api_url        = local.api_url
  pr_url         = local.pr_url
  email          = local.email
  storage_bucket = module.s3_bucket.s3_bucket_id
}

module "generate_report" {
  source = "./generate_reports"

  function_name = "generate_reports"
  handler       = "index.generate_all_reports"
  runtime       = local.runtime

  data_bucket    = data.aws_s3_bucket.data_bucket.id
  storage_bucket = module.s3_bucket.s3_bucket_id
  base_url       = "https://${data.aws_s3_bucket.data_bucket.bucket_regional_domain_name}"
  current_file   = "pr/pr.data.0.Current"
  json_file      = "pr/data.json"
  account_id     = data.aws_caller_identity.current.account_id
  lambda_source  = "${path.module}/../src/generate_reports"
}
