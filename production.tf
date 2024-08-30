module "s3-cross-account-replication" {
  source = "./modules/s3-cross-account-replication"

  source_bucket_name = "insureprobuilders-ncalifornia-prod-app-0-ss"
  source_region      = "us-west-1"
  dest_bucket_name   = "insureprobuilders-ncalifornia-prod-app-0-ss-dr"
  dest_region        = "us-west-1"

#   providers = {
#     aws.source = aws.source
#     aws.dest   = aws.dest
#   }
}