variable "bucket_name" {
  type        = string
  description = "Bucket to write reports to"
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
  description = "account id"
}
