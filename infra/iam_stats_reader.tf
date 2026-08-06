data "aws_iam_policy_document" "lambda_assume_stats" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "stats_reader" {
  name               = "planetario-movil-stats-reader"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_stats.json
}

data "aws_iam_policy_document" "stats_reader_permissions" {
  statement {
    actions   = ["dynamodb:Query"]
    resources = ["${aws_dynamodb_table.escuelas_contactos.arn}/index/estado-index"]
  }
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy" "stats_reader" {
  name   = "planetario-movil-stats-reader-permissions"
  role   = aws_iam_role.stats_reader.id
  policy = data.aws_iam_policy_document.stats_reader_permissions.json
}
