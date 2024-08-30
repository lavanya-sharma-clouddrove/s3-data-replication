variable "source_region" {
  description = "AWS Deployment region for source."
  type        = string
  default     = "us-west-1"
}

variable "dest_region" {
  description = "AWS Deployment region for destination."
  type        = string
  default     = "us-west-1"
}

variable "source_bucket_names" {
  description = "List of source bucket names."
  type        = list(string)
}

variable "dest_bucket_names" {
  description = "List of destination bucket names."
  type        = list(string)
}
