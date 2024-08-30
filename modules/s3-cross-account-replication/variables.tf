variable "source_region" {
  description = "AWS Deployment region.."
  type = string
  default = "us-west-1"
}

variable "dest_region" {
  description = "AWS Deployment region.."
  type = string
  default = "us-west-1"
}

variable "source_bucket_name" {
  description = "Your Source Bucket Name"
  type = string
  default = "insureprobuilders-ncalifornia-prod-app-0-ss"
}

variable "dest_bucket_name" {
  description = "Your Destination Bucket Name"
  type = string
  default = "insureprobuilders-ncalifornia-prod-app-0-ss-dr"
}