module "s3-cross-account-replication" {
  source = "./modules/s3-cross-account-replication"

  source_bucket_names = var.source_bucket_names
  source_region       = var.source_region
  dest_bucket_names   = var.dest_bucket_names
  dest_region         = var.dest_region

  # providers = {
  #   aws.source = aws.source
  #   aws.dest   = aws.dest
  # }
}
