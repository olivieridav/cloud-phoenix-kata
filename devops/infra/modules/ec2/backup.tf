output "backup_dumps_bucket" {
  value = aws_s3_bucket.db_dump_bucket.id
}

output "backup_ssm_command" {
  value = aws_ssm_document.mongo_db_dump.name
}

output "backup_ssm_maintenancewindow" {
  value = aws_ssm_maintenance_window.mongo_db_dump.name
}



resource "random_integer" "uniq" {
  min = 1
  max = 50000
}

resource "aws_s3_bucket" "db_dump_bucket" {
  bucket          = "phoenix-db-dumps-${var.envir}-${random_integer.uniq.result}"
  force_destroy   = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "db_dump_bucket" {
  bucket = aws_s3_bucket.db_dump_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
  depends_on = [aws_s3_bucket.db_dump_bucket]
}

resource "aws_s3_bucket_public_access_block" "db_dump_bucket" {
  bucket = aws_s3_bucket.db_dump_bucket.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket.db_dump_bucket]
}


resource "aws_s3_bucket_lifecycle_configuration" "db_dump_bucket" {
  bucket = aws_s3_bucket.db_dump_bucket.id

  rule {
    id = "ExpireAfter7days"

    filter {
    }

    expiration {
      days = var.db_backup_retention_days
    }

    status = "Enabled"
  }

  depends_on = [aws_s3_bucket.db_dump_bucket]
}

data "template_file" "dbdumpscript" {
  template = "${file("${path.module}/ssmdocument.tpl")}"
  vars = {
    db_name = var.db_name
    backup_bucket = aws_s3_bucket.db_dump_bucket.id
  }
}

resource "aws_ssm_document" "mongo_db_dump" {
  name            = "phoenix-db-dump-${var.envir}"
  document_format = "YAML"
  document_type   = "Command"

  content = data.template_file.dbdumpscript.rendered
}

resource "aws_ssm_maintenance_window" "mongo_db_dump" {
  name     = "maintenance-window-phoenix-db-dump-${var.envir}"
  schedule = var.db_backup_schedule
  duration = 3
  cutoff   = 1
  allow_unassociated_targets = true
}

resource "aws_ssm_maintenance_window_task" "mongo_db_dump" {
  max_concurrency = 2
  max_errors      = 1
  priority        = 1
  task_arn        = aws_ssm_document.mongo_db_dump.name
  task_type       = "RUN_COMMAND"
  window_id       = aws_ssm_maintenance_window.mongo_db_dump.id

  targets {
    key    = "InstanceIds"
    values = [aws_instance.phoenix_db.id]
  }

  depends_on = [aws_ssm_maintenance_window.mongo_db_dump, aws_ssm_document.mongo_db_dump]
}
