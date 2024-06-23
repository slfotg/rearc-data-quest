locals {
  data_bucket = "github-slfotg-rearc-data"
  pr_url      = "https://download.bls.gov/pub/time.series/pr/"
  email       = "slfotg@gmail.com"
  api_url     = "https://datausa.io/api/data"
}

data "aws_caller_identity" "current" {}

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

  data_bucket    = local.data_bucket
  account_id     = data.aws_caller_identity.current.account_id
  lambda_source  = "${path.module}/../src/generate_reports"
  api_url        = local.api_url
  pr_url         = local.pr_url
  email          = local.email
  storage_bucket = module.s3_bucket.s3_bucket_id
}

module "generate_report" {
  source = "./generate_reports"

  bucket_name    = local.data_bucket
  storage_bucket = module.s3_bucket.s3_bucket_id
  base_url       = "https://github-slfotg-rearc-data.s3.us-east-2.amazonaws.com"
  current_file   = "pr/pr.data.0.Current"
  json_file      = "pr/data.json"
  account_id     = data.aws_caller_identity.current.account_id
  lambda_source  = "${path.module}/../src/generate_reports"
}
