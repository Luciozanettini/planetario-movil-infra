data "archive_file" "escuelas_enviador" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/escuelas_enviador"
  output_path = "${path.module}/../lambda/escuelas_enviador.zip"
}

resource "aws_lambda_function" "escuelas_enviador" {
  function_name    = "planetario-movil-escuelas-enviador"
  role             = aws_iam_role.lambda_escuelas_enviador.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.escuelas_enviador.output_path
  source_code_hash = data.archive_file.escuelas_enviador.output_base64sha256
  timeout          = 300
  memory_size      = 512

  environment {
    variables = {
      TABLE_NAME          = aws_dynamodb_table.escuelas_contactos.name
      SENDER               = "Fundación Planetarium <contacto@planetariomendoza.com.ar>"
      REPLY_TO             = "juanpablozanettini@gmail.com"
      ATTACHMENTS_BUCKET   = aws_s3_bucket.escuelas_uploads.bucket
      ATTACHMENTS_PREFIX   = "attachments/"
      BATCH_SIZE           = "25"
    }
  }
}

resource "aws_cloudwatch_log_group" "escuelas_enviador" {
  name              = "/aws/lambda/${aws_lambda_function.escuelas_enviador.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_event_rule" "escuelas_enviador_schedule" {
  name                = "planetario-movil-escuelas-enviador-schedule"
  description         = "Dispara el envio de mails a escuelas, cada hora, en horario 9-18hs Mendoza (UTC-3)"
  schedule_expression = "cron(0 12-21 * * ? *)"
  state               = "DISABLED"
}

resource "aws_cloudwatch_event_target" "escuelas_enviador_target" {
  rule      = aws_cloudwatch_event_rule.escuelas_enviador_schedule.name
  target_id = "escuelas-enviador-lambda"
  arn       = aws_lambda_function.escuelas_enviador.arn
}

resource "aws_lambda_permission" "eventbridge_invoke_enviador" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.escuelas_enviador.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.escuelas_enviador_schedule.arn
}
