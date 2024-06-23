locals {
  function_name = "update_data"
  handler       = "index.update_data"
  runtime       = "python3.12"
}

module "eventbridge" {
  source = "terraform-aws-modules/eventbridge/aws"

  create_bus = true
  bus_name   = "schedule_bus"

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

  function_name = local.function_name
  handler       = local.handler
  runtime       = local.runtime

  source_path = var.lambda_source

  store_on_s3 = true
  s3_bucket   = var.storage_bucket
  s3_prefix   = "lambda-builds/"

  artifacts_dir = "${path.root}/.terraform/lambda-builds/"

  layers = [
    module.lambda_layer_s3.lambda_layer_arn,
  ]

  environment_variables = {
    BUCKET_NAME  = var.data_bucket
    BASE_URL     = var.pr_url
    USER_AGENT   = var.email
    API_BASE_URL = var.api_url
  }

  trusted_entities = ["scheduler.amazonaws.com"]

  create_current_version_allowed_triggers = false
  allowed_triggers = {
    ScheduleRule = {
      principal  = "scheduler.amazonaws.com"
      source_arn = module.eventbridge.eventbridge_schedule_arns["lambda-cron"]
    }
  }

  #   assume_role_policy_statements = {
  #     account_root = {
  #       effect  = "Allow",
  #       actions = ["sts:AssumeRole"],
  #       principals = {
  #         account_principal = {
  #           type        = "AWS",
  #           identifiers = ["arn:aws:iam::${var.account_id}:root"]
  #         }
  #       }
  #     }
  #   }

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
                    "arn:aws:s3:::${var.data_bucket}",
                    "arn:aws:s3:::${var.data_bucket}/*"
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

  layer_name          = "update-data-layer-s3"
  description         = "uupdate_data layer"
  compatible_runtimes = [local.runtime]

  source_path = var.lambda_source

  store_on_s3 = true
  s3_bucket   = var.storage_bucket
}
