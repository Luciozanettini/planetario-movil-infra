# HTTP API (no REST API): más simple y más barato que el API Gateway
# "clásico" (REST API) para un caso de uso tan directo como este -
# un solo endpoint, sin necesidad de las features avanzadas del tipo REST.
resource "aws_apigatewayv2_api" "leads" {
  name          = "${var.project_name}-leads-api"
  protocol_type = "HTTP"

  # CORS gestionado acá, no en la Lambda - así el navegador puede llamar
  # a este endpoint desde la landing sin que el fetch() sea bloqueado.
  # Restringido SOLO a tu dominio, no "*" - un origen abierto permitiría
  # que cualquier sitio externo dispare este endpoint desde el navegador
  # de un visitante.
  cors_configuration {
    allow_origins = ["https://${var.domain_name}", "https://www.${var.domain_name}"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_integration" "leads" {
  api_id                 = aws_apigatewayv2_api.leads.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.leads.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "leads" {
  api_id    = aws_apigatewayv2_api.leads.id
  route_key = "POST /leads"
  target    = "integrations/${aws_apigatewayv2_integration.leads.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.leads.id
  name        = "$default"
  auto_deploy = true

  # Throttling: límite de requests por segundo. Con este tráfico esperado
  # (formulario de contacto, no una API pública de alto volumen) 10 req/s
  # sostenido con ráfagas de hasta 20 es más que suficiente, y protege
  # contra un posible abuso o bot que intente saturar el endpoint.
  default_route_settings {
    throttling_burst_limit = 20
    throttling_rate_limit  = 10
  }
}

# Sin este permiso, API Gateway no tiene autorización para invocar la
# Lambda aunque la integración esté configurada - es un paso que se
# olvida seguido al armar esto a mano en la consola.
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.leads.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.leads.execution_arn}/*/*"
}
