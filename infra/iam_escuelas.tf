data "aws_iam_policy_document" "lambda_assume_escuelas" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_escuelas_importador" {
  name               = "planetario-movil-escuelas-importador"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_escuelas.json
}

data "aws_iam_policy_document" "lambda_escuelas_importador_permissions" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.escuelas_uploads.arn}/imports/*"]
  }
  statement {
    actions   = ["dynamodb:PutItem"]
    resources = [aws_dynamodb_table.escuelas_contactos.arn]
  }
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy" "lambda_escuelas_importador" {
  name   = "planetario-movil-escuelas-importador-permissions"
  role   = aws_iam_role.lambda_escuelas_importador.id
  policy = data.aws_iam_policy_document.lambda_escuelas_importador_permissions.json
}