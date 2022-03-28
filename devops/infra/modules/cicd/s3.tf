resource "random_integer" "uniq" {
  min = 1
  max = 50000
}


resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket          = "phoenix-codepipeline-bucket-${random_integer.uniq.result}"
  force_destroy   = true
  tags = var.tags
}


resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_bucket_encryption" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_block" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}


