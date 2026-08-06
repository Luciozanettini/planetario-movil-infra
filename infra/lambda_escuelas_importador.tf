data "archive_file" "escuelas_importador" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/escuelas_importador"
  output_path = "${path.module}/../lambda/escuelas_importador.zip"
}

resource "aws_lambda_function" "escuelas_importador" {
  function_name    = "planetario-movil-escuelas-importador"
  role             = aws_iam_role.lambda_escuelas_importador.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.escuelas_importador.output_path
  source_code_hash = data.archive_file.escuelas_importador.output_base64sha256
  timeout          = 60

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.escuelas_contactos.name
    }
  }
}

resource "aws_lambda_permission" "s3_invoke_importador" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.escuelas_importador.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.escuelas_uploads.arn
}

resource "aws_cloudwatch_log_group" "escuelas_importador" {
  name              = "/aws/lambda/${aws_lambda_function.escuelas_importador.function_name}"
  retention_in_days = 30
}
