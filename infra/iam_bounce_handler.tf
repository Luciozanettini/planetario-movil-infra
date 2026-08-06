data "aws_iam_policy_document" "lambda_assume_bounce_handler" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bounce_handler" {
  name               = "planetario-movil-bounce-handler"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_bounce_handler.json
}

data "aws_iam_policy_document" "bounce_handler_permissions" {
  statement {
    actions   = ["dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.escuelas_contactos.arn]
  }
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy" "bounce_handler" {
  name   = "planetario-movil-bounce-handler-permissions"
  role   = aws_iam_role.bounce_handler.id
  policy = data.aws_iam_policy_document.bounce_handler_permissions.json
}
