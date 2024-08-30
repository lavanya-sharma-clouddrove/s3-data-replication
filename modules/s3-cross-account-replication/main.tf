terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  alias   = "source"
  region  = var.source_region
  profile = "source"
}

provider "aws" {
  alias   = "dest"
  region  = var.dest_region
  profile = "dest"
}

# Loop through source and destination buckets
resource "aws_iam_role" "source_replication" {
  for_each = toset(var.source_bucket_names)
  provider = aws.source
  name     = "${each.key}_replication_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "s3.amazonaws.com"
        },
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "source_replication" {
  for_each = toset(var.source_bucket_names)
  provider = aws.source
  name     = "${each.key}_replication_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ],
        Effect   = "Allow",
        Resource = aws_s3_bucket.source[each.key].arn
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.source[each.key].arn}/*"
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.destination[each.key].arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "source_replication" {
  for_each = toset(var.source_bucket_names)
  provider   = aws.source
  role       = aws_iam_role.source_replication[each.key].name
  policy_arn = aws_iam_policy.source_replication[each.key].arn
}

resource "aws_s3_bucket" "source" {
  for_each = toset(var.source_bucket_names)
  provider      = aws.source
  bucket        = each.key
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "source" {
  for_each = toset(var.source_bucket_names)
  provider = aws.source
  bucket   = aws_s3_bucket.source[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "source" {
  for_each = toset(var.source_bucket_names)
  provider = aws.source
  depends_on = [aws_s3_bucket_versioning.source]

  role   = aws_iam_role.source_replication[each.key].arn
  bucket = aws_s3_bucket.source[each.key].id

  rule {
    id = "cross-replication"
    delete_marker_replication {
      status = "Disabled"
    }
    source_selection_criteria {
      replica_modifications {
        status = "Enabled"
      }
    }
    filter {
      prefix = ""
    }
    status = "Enabled"

    destination {
      bucket = aws_s3_bucket.destination[each.key].arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "source" {
  for_each = toset(var.source_bucket_names)
  provider = aws.source
  bucket   = aws_s3_bucket.source[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "dest_replication" {
  for_each = toset(var.dest_bucket_names)
  provider = aws.dest
  name     = "${each.key}_replication_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "s3.amazonaws.com"
        },
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "dest_replication" {
  for_each = toset(var.dest_bucket_names)
  provider = aws.dest
  name     = "${each.key}_replication_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ],
        Effect   = "Allow",
        Resource = aws_s3_bucket.destination[each.key].arn
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.destination[each.key].arn}/*"
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.source[each.key].arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dest_replication" {
  for_each = toset(var.dest_bucket_names)
  provider   = aws.dest
  role       = aws_iam_role.dest_replication[each.key].name
  policy_arn = aws_iam_policy.dest_replication[each.key].arn
}

resource "aws_s3_bucket" "destination" {
  for_each = toset(var.dest_bucket_names)
  provider      = aws.dest
  bucket        = each.key
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "destination" {
  for_each = toset(var.dest_bucket_names)
  provider = aws.dest
  bucket   = aws_s3_bucket.destination[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "destination" {
  for_each = toset(var.dest_bucket_names)
  provider = aws.dest
  bucket   = aws_s3_bucket.destination[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "dest_bucket_policy" {
  for_each = toset(var.dest_bucket_names)
  provider = aws.dest
  bucket   = aws_s3_bucket.destination[each.key].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "ObjectLevelPermission",
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.source_replication[each.key].arn
        },
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ],
        Resource = "${aws_s3_bucket.destination[each.key].arn}/*"
      },
      {
        Sid = "BucketLevelPermission",
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.source_replication[each.key].arn
        },
        Action = [
          "s3:List*",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning"
        ],
        Resource = aws_s3_bucket.destination[each.key].arn
      }
    ]
  })
}
