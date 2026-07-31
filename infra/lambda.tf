# Empaqueta el código de la Lambda en un .zip automáticamente en cada
# apply. No necesitamos node_modules acá: los clientes de AWS SDK v3
# (DynamoDB, SES) vienen preinstalados en el runtime de Lambda Node.js 20,
# no hace falta bundlearlos nosotros para este caso simple.
data "archive_file" "leads_lambda" {
  type        = "zip"
  source_file = "../lambda/index.js"
  output_path = "../lambda/leads.zip"
}

resource "aws_lambda_function" "leads" {
  function_name    = "${var.project_name}-leads"
  role             = aws_iam_role.lambda_leads.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.leads_lambda.output_path
  source_code_hash = data.archive_file.leads_lambda.output_base64sha256
  timeout          = 10 # de sobra para un PutItem + SendEmail; si tarda más, algo anda mal

  environment {
    variables = {
      LEADS_TABLE     = aws_dynamodb_table.leads.name
      SENDER_EMAIL    = "no-reply@${var.domain_name}"
      RECIPIENT_EMAIL = var.contact_email
    }
  }
}

# Grupo de logs con retención acotada: sin esto, CloudWatch Logs
# guardaría los logs para siempre y eso, aunque barato, se acumula
# como costo silencioso con el tiempo.
resource "aws_cloudwatch_log_group" "leads_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.leads.function_name}"
  retention_in_days = 30
}
