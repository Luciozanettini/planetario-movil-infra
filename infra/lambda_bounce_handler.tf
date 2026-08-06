data "archive_file" "bounce_handler" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/bounce_handler"
  output_path = "${path.module}/../lambda/bounce_handler.zip"
}

resource "aws_lambda_function" "bounce_handler" {
  function_name    = "planetario-movil-bounce-handler"
  role             = aws_iam_role.bounce_handler.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.bounce_handler.output_path
  source_code_hash = data.archive_file.bounce_handler.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.escuelas_contactos.name
    }
  }
}

resource "aws_cloudwatch_log_group" "bounce_handler" {
  name              = "/aws/lambda/${aws_lambda_function.bounce_handler.function_name}"
  retention_in_days = 30
}
