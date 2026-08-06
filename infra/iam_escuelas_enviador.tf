data "aws_iam_policy_document" "lambda_assume_enviador" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_escuelas_enviador" {
  name               = "planetario-movil-escuelas-enviador"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_enviador.json
}

data "aws_iam_policy_document" "lambda_escuelas_enviador_permissions" {
  statement {
    actions   = ["dynamodb:Query", "dynamodb:UpdateItem"]
    resources = [
      aws_dynamodb_table.escuelas_contactos.arn,
      "${aws_dynamodb_table.escuelas_contactos.arn}/index/estado-index",
    ]
  }
  statement {
    actions   = ["ses:SendRawEmail"]
    resources = ["*"]
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.escuelas_uploads.arn}/attachments/*"]
  }
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy" "lambda_escuelas_enviador" {
  name   = "planetario-movil-escuelas-enviador-permissions"
  role   = aws_iam_role.lambda_escuelas_enviador.id
  policy = data.aws_iam_policy_document.lambda_escuelas_enviador_permissions.json
}