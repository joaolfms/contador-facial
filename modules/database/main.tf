resource "aws_dynamodb_table" "faces" {
  name           = "EventFaces"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "FaceId"

  attribute {
    name = "FaceId"
    type = "S"
  }

  attribute {
    name = "Status"
    type = "S"
  }

  global_secondary_index {
    name               = "StatusIndex"
    hash_key           = "Status"
    projection_type    = "ALL"
  }

  tags = {
    Name = "EventFacesTable"
  }
}