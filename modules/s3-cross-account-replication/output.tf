output "source_bucket_arns" {
  value = [for bucket in aws_s3_bucket.source : bucket.arn]
}

output "dest_bucket_arns" {
  value = [for bucket in aws_s3_bucket.destination : bucket.arn]
}

output "source_replication_role_arns" {
  value = [for role in aws_iam_role.source_replication : role.arn]
}

output "dest_replication_role_arns" {
  value = [for role in aws_iam_role.dest_replication : role.arn]
}
