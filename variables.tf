variable "source_region" {
  description = "The AWS region for the source bucket."
  type        = string
  default     = "us-west-1"
}

variable "dest_region" {
  description = "The AWS region for the destination bucket."
  type        = string
  default     = "us-west-1"
}

variable "source_bucket_names" {
  description = "The list of source S3 bucket names."
  type        = list(string)
}

variable "dest_bucket_names" {
  description = "The list of destination S3 bucket names."
  type        = list(string)
}

