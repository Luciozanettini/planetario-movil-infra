# PAY_PER_REQUEST en vez de capacidad fija (provisioned): no pagás nada
# si no hay tráfico, y con el volumen esperado (pedidos de presupuesto de
# escuelas, no miles por segundo) sale más barato que reservar capacidad.
resource "aws_dynamodb_table" "leads" {
  name         = "${var.project_name}-leads"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Permite restaurar la tabla a cualquier punto de los últimos 35 días.
  # Es la red de seguridad contra un delete accidental o un bug que
  # sobrescriba datos.
  point_in_time_recovery {
    enabled = true
  }
}
