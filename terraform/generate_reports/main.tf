locals {
  function_name = "generate_reports"
  handler       = "index.generate_all_reports"
  runtime       = "python3.12"
}

module "generate_reports_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = local.function_name
  handler       = local.handler
  runtime       = local.runtime

  source_path = var.lambda_source

  store_on_s3 = true
  s3_bucket   = var.storage_bucket
  s3_prefix   = "lambda-builds/"

  artifacts_dir = "${path.root}/.terraform/lambda-builds/"

  environment_variables = {
    BUCKET_NAME  = var.data_bucket
    BASE_URL     = var.base_url
    CURRENT_FILE = var.current_file
    JSON_FILE    = var.json_file
  }

  # assume_role_policy_statements = {
  #   account_root = {
  #     effect  = "Allow",
  #     actions = ["sts:AssumeRole"],
  #     principals = {
  #       account_principal = {
  #         type        = "AWS",
  #         identifiers = ["arn:aws:iam::${var.account_id}:root"]
  #       }
  #     }
  #   }
  # }

  attach_policy_statements = true
  policy_statements = {
    s3_write = {
      effect    = "Allow",
      actions   = ["s3:PutObject"],
      resources = ["arn:aws:s3:::${var.data_bucket}/*"]
    }
  }

  timeout = 30
  timeouts = {
    create = "20m"
    update = "20m"
    delete = "20m"
  }
}

module "s3_notifications" {
  source = "terraform-aws-modules/s3-bucket/aws//modules/notification"

  bucket = var.data_bucket

  eventbridge = true

  lambda_notifications = {
    lambda1 = {
      function_arn  = module.generate_reports_function.lambda_function_arn
      function_name = module.generate_reports_function.lambda_function_name
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = var.json_file
    }
  }
}
