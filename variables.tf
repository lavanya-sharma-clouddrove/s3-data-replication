variable "source_region" {
  description = "The AWS region for the source bucket."
  type        = string
  default     = "us-west-1" // Optional: default value can be set or removed
}

variable "dest_region" {
  description = "The AWS region for the destination bucket."
  type        = string
  default     = "us-west-1" // Optional: default value can be set or removed
}

variable "source_bucket_name" {
  description = "The name of the source S3 bucket."
  type        = string
  # default     = "source-xyz-abc-123456" // Optional: default value can be set or removed
}

variable "dest_bucket_name" {
  description = "The name of the destination S3 bucket."
  type        = string
  # default     = "destination-xyz-abc-123456" // Optional: default value can be set or removed
}
