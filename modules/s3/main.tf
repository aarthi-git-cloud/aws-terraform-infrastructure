resource "aws_s3_bucket" "app" {
  bucket = "${var.project_name}-${var.environment}-app-storage"
}

resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id
  versioning_configuration { status = "Enabled" }
}

# Encrypt all objects at rest using AWS managed key
resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# Block all public access — objects are private by default
resource "aws_s3_bucket_public_access_block" "app" {
  bucket                  = aws_s3_bucket.app.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

variable "project_name" { type = string }
variable "environment"  { type = string }

output "bucket_name" { value = aws_s3_bucket.app.bucket }
