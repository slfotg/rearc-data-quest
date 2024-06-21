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

  source_path = "../src/lambda"
}
