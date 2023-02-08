# Create an S3 bucket

variable "lifecycle_rules" {
  type = any
  default = {
    "dev" = [
      {
        id      = "clean_no_current_version"
        enabled = true
        noncurrent_version_expiration = {
          days = 7
        }
        expiration = {
          days                         = 0
          expired_object_delete_marker = true
        }
      },
      {
        id                                     = "cleanup_incomplete_multipart_uploads"
        enabled                                = true
        abort_incomplete_multipart_upload_days = 7
        expiration = {
          days                         = 0
          expired_object_delete_marker = false
        }
      },
      { id                                     = "queryable"
        prefix                                 = "queryable/"
        abort_incomplete_multipart_upload_days = null
        enabled                                = true
        expiration = {
          days                         = 15
          expired_object_delete_marker = null
        }
      },
      { id                                     = "queryable-parquet"
        prefix                                 = "queryable-parquet/"
        abort_incomplete_multipart_upload_days = null
        enabled                                = true
        expiration = {
          days                         = 90
          expired_object_delete_marker = null
        }

    }]
    "staging" = [
      {
        id      = "clean_no_current_version"
        enabled = true
        noncurrent_version_expiration = {
          days = 7
        }
        expiration = {
          days                         = 0
          expired_object_delete_marker = true
        }
      },
      {
        id                                     = "cleanup_incomplete_multipart_uploads"
        enabled                                = true
        abort_incomplete_multipart_upload_days = 7
        expiration = {
          days                         = 0
          expired_object_delete_marker = false
        }
      },
      {
        id                                     = "queryable"
        prefix                                 = "queryable/"
        abort_incomplete_multipart_upload_days = null
        enabled                                = true
        expiration = {
          days                         = 15
          expired_object_delete_marker = null
        }
      },
      {
        id                                     = "queryable-parquet"
        prefix                                 = "queryable-parquet/"
        abort_incomplete_multipart_upload_days = null
        enabled                                = true
        transition = [{
          days          = 0
          storage_class = "INTELLIGENT_TIERING"
        }]
        expiration = {
          days                         = 90
          expired_object_delete_marker = null
        }
      }
    ]
  }
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

resource "aws_s3_bucket" "example" {
  bucket = "logs-${var.region}-${var.environment}"
  acl    = "log-delivery-write"

  tags = local.tags[var.environment]

  force_destroy = true

  object_lock_configuration {
    object_lock_enabled = "Enabled"

    rule {
      default_retention {
        mode = "COMPLIANCE"
        days = 5
      }
    }
  }

  replication_configuration {
    role = aws_iam_role.replication.arn

    rules {
      id     = "foobar"
      status = "Enabled"

      filter {
        tags = {}
      }
      destination {
        bucket        = aws_s3_bucket.destination.arn
        storage_class = "STANDARD"

        replication_time {
          status  = "Enabled"
          minutes = 15
        }

        metrics {
          status  = "Enabled"
          minutes = 15
        }
      }
    }
  }

  dynamic "lifecycle_rule" {
    for_each = try(jsondecode(var.lifecycle_rules[var.environment]), var.lifecycle_rules[var.environment])

    content {
      id                                     = lookup(lifecycle_rule.value, "id", null)
      prefix                                 = lookup(lifecycle_rule.value, "prefix", null)
      tags                                   = lookup(lifecycle_rule.value, "tags", null)
      abort_incomplete_multipart_upload_days = lookup(lifecycle_rule.value, "abort_incomplete_multipart_upload_days", null)
      enabled                                = lifecycle_rule.value.enabled

      # Max 1 block - expiration
      dynamic "expiration" {
        for_each = length(keys(lookup(lifecycle_rule.value, "expiration", {}))) == 0 ? [] : [lookup(lifecycle_rule.value, "expiration", {})]

        content {
          date                         = lookup(expiration.value, "date", null)
          days                         = lookup(expiration.value, "days", null)
          expired_object_delete_marker = lookup(expiration.value, "expired_object_delete_marker", null)
        }
      }

      # Several blocks - transition
      dynamic "transition" {
        for_each = lookup(lifecycle_rule.value, "transition", [])

        content {
          date          = lookup(transition.value, "date", null)
          days          = lookup(transition.value, "days", null)
          storage_class = transition.value.storage_class
        }
      }

      # Max 1 block - noncurrent_version_expiration
      dynamic "noncurrent_version_expiration" {
        for_each = length(keys(lookup(lifecycle_rule.value, "noncurrent_version_expiration", {}))) == 0 ? [] : [lookup(lifecycle_rule.value, "noncurrent_version_expiration", {})]

        content {
          days = lookup(noncurrent_version_expiration.value, "days", null)
        }
      }

      # Several blocks - noncurrent_version_transition
      dynamic "noncurrent_version_transition" {
        for_each = lookup(lifecycle_rule.value, "noncurrent_version_transition", [])

        content {
          days          = lookup(noncurrent_version_transition.value, "days", null)
          storage_class = noncurrent_version_transition.value.storage_class
        }
      }
    }
  }

  resource "aws_kms_key" "mykey" {
    description             = "This key is used to encrypt bucket objects"
    deletion_window_in_days = 10
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.mykey.arn
        sse_algorithm = "aws:kms"
      }
    }
  }

  logging {
    target_bucket = "example-usw2-${var.environment}-logs"
    target_prefix = "s3_access_logs/example-logs-${var.region}-${var.environment}/"
  }

  versioning {
    enabled = true
  }

  request_payer = var.environment == "prod" ? "Requester" : null
}

data "aws_iam_policy_document" "bucket_example" {
  statement {
    sid       = "protect versions"
    effect    = "Deny"
    actions   = ["s3:DeleteObjectVersion"]
    resources = ["${aws_s3_bucket.example.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    sid     = "secure transport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.example.arn,
      "${aws_s3_bucket.example.arn}/*",
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.example.id
  policy = data.aws_iam_policy_document.bucket_example.json
}

resource "aws_s3_bucket_public_access_block" "example" {
    bucket = aws_s3_bucket.example.id

    block_public_acls       = True
    block_public_policy     = True
    ignore_public_acls      = True
    restrict_public_buckets = True
  }

resource "aws_s3_bucket_inventory" "example" {
  bucket                   = aws_s3_bucket.example.id
  name                     = "export"
  included_object_versions = "Current"
  schedule { frequency = "Weekly" }
  destination {
    bucket {
      format     = "CSV"
      bucket_arn = aws_s3_bucket.example_inventory_bucket.arn
      encryption {
        sse_kms { key_id = aws_kms_key.s3.arn }
      }
    }
  }
  optional_fields = [
    "LastModifiedDate", "ReplicationStatus", "Size", "StorageClass"
  ]
}

output "example_s3_bucket" {
  value = aws_s3_bucket.example.bucket_domain_name
}

# Allow rundeck access to the bucket

data "aws_iam_policy_document" "rundeck_s3_bucket" {
  statement {
    sid       = "1"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.example.arn]
  }

  statement {
    sid       = "2"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["${aws_s3_bucket.example.arn}/*"]
  }
}

resource "aws_iam_policy" "rundeck_s3_policy" {
  name        = "rundeck_s3_policy_logs_${var.environment}"
  description = "IAM policy to allow Rundeck to upload execution logs to S3"
  policy      = data.aws_iam_policy_document.rundeck_s3_bucket.json

  lifecycle {
    create_before_destroy = true
  }
}

# Attach the Custom Rundeck S3 policy to the role
resource "aws_iam_role_policy_attachment" "rundeck_s3_policy_attach" {
  role       = module.rundeck.rundeck_iam_role_name
  policy_arn = aws_iam_policy.rundeck_s3_policy.arn
}