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

variable "base_url" {
  description = "Base URL where the data is"
  type        = string
}

variable "current_file" {
  description = "Path to current file"
  type        = string
}

variable "json_file" {
  description = "Path to json file"
  type        = string
}

variable "account_id" {
  description = "IAM Role Id"
  type        = string
}

variable "lambda_source" {
  description = "Source of code for lambda function"
  type        = string
}
