variable "data_bucket" {
  type        = string
  description = "Bucket that stores datasets"
}

variable "storage_bucket" {
  type        = string
  description = "Bucket to store lambda package"
}

variable "base_url" {
  type        = string
  description = "Base URL where the data is"
}

variable "current_file" {
  type        = string
  description = "Path to current file"
}

variable "json_file" {
  type        = string
  description = "Path to json file"
}

variable "account_id" {
  type        = string
  description = "IAM Role Id"
}

variable "lambda_source" {
  type        = string
  description = "Source of code for lambda function"
}
