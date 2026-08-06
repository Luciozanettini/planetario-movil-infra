data "archive_file" "stats_reader" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/stats_reader"
  output_path = "${path.module}/../lambda/stats_reader.zip"
}

resource "aws_lambda_function" "stats_reader" {
  function_name    = "planetario-movil-stats-reader"
  role             = aws_iam_role.stats_reader.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.stats_reader.output_path
  source_code_hash = data.archive_file.stats_reader.output_base64sha256
  timeout          = 15

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.escuelas_contactos.name
    }
  }
}

resource "aws_cloudwatch_log_group" "stats_reader" {
  name              = "/aws/lambda/${aws_lambda_function.stats_reader.function_name}"
  retention_in_days = 30
}
