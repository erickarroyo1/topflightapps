resource "aws_s3_bucket" "terraform_bucket_state" {
  bucket   = "${var.app_name}-bucket-state"
  tags     = { Name = "${var.app_name}-bucket-state" }
  provider = aws.landing-zone-account
}

resource "aws_s3_bucket_versioning" "state" {
  bucket   = aws_s3_bucket.terraform_bucket_state.id
  provider = aws.landing-zone-account
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket   = aws_s3_bucket.terraform_bucket_state.id
  provider = aws.landing-zone-account
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.state.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.terraform_bucket_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  provider                = aws.landing-zone-account
}

# Reject any request that is not over TLS.
data "aws_iam_policy_document" "state_tls_only" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.terraform_bucket_state.arn,
      "${aws_s3_bucket.terraform_bucket_state.arn}/*"
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket   = aws_s3_bucket.terraform_bucket_state.id
  policy   = data.aws_iam_policy_document.state_tls_only.json
  provider = aws.landing-zone-account
}
