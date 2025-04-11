resource "aws_s3_bucket" "backup" {
  bucket = "event-backup-${random_id.bucket_suffix.hex}"
  tags = {
    Name = "EventBackup"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}