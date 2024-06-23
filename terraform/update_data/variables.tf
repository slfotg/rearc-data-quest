variable "data_bucket" {
  type        = string
  description = "Bucket that stores datasets"
}

variable "storage_bucket" {
  type        = string
  description = "Bucket to store lambda package"
}

variable "pr_url" {
  type        = string
  description = "Public API URL for BLS dataset"
}

variable "email" {
  type        = string
  description = "Email address to use for requests to BLS API"
}

variable "api_url" {
  type        = string
  description = "Data USA API URL"
}

variable "account_id" {
  type        = string
  description = "IAM Role id"
}

variable "lambda_source" {
  type        = string
  description = "Source of code for lambda function"
}
