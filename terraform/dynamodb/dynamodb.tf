variable project_name {}

resource aws_dynamodb_table dynamodb_table {
  name           = "${var.project_name}-dynamodb-table"
  read_capacity  = 3
  write_capacity = 3
  hash_key       = "Etag"

  attribute {
    name = "Etag"
    type = "S"
  }
}

output table_name {
  value = aws_dynamodb_table.dynamodb_table.name
}

output table_arn {
  value = aws_dynamodb_table.dynamodb_table.arn
}