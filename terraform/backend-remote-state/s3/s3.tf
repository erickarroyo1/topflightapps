resource "aws_s3_bucket" "terraform_bucket_state" {
  bucket = "${var.app_name}-bucket-state"
  versioning {
    enabled = true
  }
  tags = {
    Name = "${var.app_name}-bucket-state"
  }
  provider = aws.landing-zone-account
}
