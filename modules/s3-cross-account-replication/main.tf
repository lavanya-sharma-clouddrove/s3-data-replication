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

resource "aws_iam_role" "source_replication" {
  provider = aws.source
  name     = "${var.source_bucket_name}_replication_role"

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
  provider = aws.source
  name     = "${var.source_bucket_name}_replication_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ],
        Effect   = "Allow",
        Resource = aws_s3_bucket.source.arn
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.source.arn}/*"
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.destination.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "source_replication" {
  provider   = aws.source
  role       = aws_iam_role.source_replication.name
  policy_arn = aws_iam_policy.source_replication.arn
}

resource "aws_s3_bucket" "source" {
  provider      = aws.source
  bucket        = var.source_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "source" {
  provider = aws.source
  bucket   = aws_s3_bucket.source.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "source" {
  provider = aws.source
  depends_on = [aws_s3_bucket_versioning.source]

  role   = aws_iam_role.source_replication.arn
  bucket = aws_s3_bucket.source.id

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
      bucket = aws_s3_bucket.destination.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "source" {
  provider = aws.source
  bucket   = aws_s3_bucket.source.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "dest_replication" {
  provider = aws.dest
  name     = "${var.dest_bucket_name}_replication_role"

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
  provider = aws.dest
  name     = "${var.dest_bucket_name}_replication_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ],
        Effect   = "Allow",
        Resource = aws_s3_bucket.destination.arn
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.destination.arn}/*"
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.source.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dest_replication" {
  provider   = aws.dest
  role       = aws_iam_role.dest_replication.name
  policy_arn = aws_iam_policy.dest_replication.arn
}

resource "aws_s3_bucket" "destination" {
  provider      = aws.dest
  bucket        = var.dest_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "destination" {
  provider = aws.dest
  bucket   = aws_s3_bucket.destination.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "destination" {
  provider = aws.dest
  bucket   = aws_s3_bucket.destination.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "dest_bucket_policy" {
  provider = aws.dest
  bucket   = aws_s3_bucket.destination.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "ObjectLevelPermission",
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.source_replication.arn
        },
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ],
        Resource = "${aws_s3_bucket.destination.arn}/*"
      },
      {
        Sid = "BucketLevelPermission",
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.source_replication.arn
        },
        Action = [
          "s3:List*",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning"
        ],
        Resource = aws_s3_bucket.destination.arn
      }
    ]
  })
}
