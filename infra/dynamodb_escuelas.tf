resource "aws_dynamodb_table" "escuelas_contactos" {
  name         = "planetario-movil-escuelas-contactos"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "email"

  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "estado"
    type = "S"
  }

  global_secondary_index {
    name            = "estado-index"
    hash_key        = "estado"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Project = var.project_name
  }
}