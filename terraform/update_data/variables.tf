variable "data_bucket" {
  type = string
}

variable "storage_bucket" {
  type        = string
  description = "Bucket to store lambda package"
}

variable "pr_url" {
  type = string
}

variable "email" {
  type = string
}

variable "api_url" {
  type = string
}

variable "account_id" {
  type = string
}

variable "lambda_source" {
  type        = string
  description = "Source of code for lambda function"
}
