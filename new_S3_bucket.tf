resource "aws_s3_bucket" "example" {
  bucket = "mybucket"
  ignore_public_acls = true
  versioning {
        enabled = true
    }
  
  server_side_encryption_configuration {
     rule {
       apply_server_side_encryption_by_default {
         kms_master_key_id = "arn"
         sse_algorithm     = "aws:kms"
       }
     }
   }
  
  logging {
        target_bucket = "target-bucket"
    }
  
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "good_example" {
  bucket = aws_s3_bucket.example.id 
  block_public_policy = true
}

resource "aws_s3_bucket_public_access_block" "good_example" {
  bucket = aws_s3_bucket.example.id
  block_public_acls = true
}

resource "aws_s3_bucket_object_lock_configuration" "example" {
  bucket = aws_s3_bucket.example.bucket
  object_lock_enabled = Enabled
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.mykey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}
