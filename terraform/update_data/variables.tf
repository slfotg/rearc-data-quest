variable "function_name" {
  description = "A unique name for your Lambda Function"
  type        = string
}

variable "handler" {
  description = "Lambda Function entrypoint in your code"
  type        = string
}

variable "runtime" {
  description = "Lambda Function runtime"
  type        = string
}

variable "data_bucket" {
  description = "Bucket that stores datasets"
  type        = string
}

variable "storage_bucket" {
  description = "Bucket to store lambda package"
  type        = string
}

variable "pr_url" {
  description = "Public API URL for BLS dataset"
  type        = string
}

variable "email" {
  description = "Email address to use for requests to BLS API"
  type        = string
}

variable "api_url" {
  description = "Data USA API URL"
  type        = string
}

variable "account_id" {
  description = "IAM Role id"
  type        = string
}

variable "lambda_source" {
  description = "Source of code for lambda function"
  type        = string
}
