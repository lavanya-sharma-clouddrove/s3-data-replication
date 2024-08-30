output "source_bucket_arn" {
  value = aws_s3_bucket.source.arn
}

output "dest_bucket_arn" {
  value = aws_s3_bucket.destination.arn
}

output "source_replication_role_arn" {
  description = "The ARN of the source IAM role used for replication"
  value       = aws_iam_role.source_replication.arn
}

# output "dest_bucket_arn" {
#   description = "The ARN of the destination S3 bucket"
#   value       = aws_s3_bucket.destination.arn
# }