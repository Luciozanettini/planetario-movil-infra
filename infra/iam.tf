data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_leads" {
  name               = "${var.project_name}-leads-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Policy administrada de AWS, solo da permiso de escribir logs en
# CloudWatch - es el mínimo indispensable para poder debuggear la Lambda.
resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_leads.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy propia, acotada SOLO a lo que esta Lambda necesita: escribir en
# SU tabla de DynamoDB (no en cualquier tabla de la cuenta) y mandar mails.
# Esto es lo opuesto a darle AdministratorAccess a la Lambda "porque total
# funciona" - si mañana esta función tiene una vulnerabilidad, el atacante
# solo puede escribir leads y mandar mails, nada más.
data "aws_iam_policy_document" "lambda_leads_permissions" {
  statement {
    sid       = "WriteLeadsTable"
    effect    = "Allow"
    actions   = ["dynamodb:PutItem"]
    resources = [aws_dynamodb_table.leads.arn]
  }

  statement {
    sid    = "SendNotificationEmail"
    effect = "Allow"
    # SES no permite acotar ses:SendEmail a un ARN de identidad específico
    # de forma práctica en esta acción - "*" es la práctica estándar acá,
    # el acotamiento real ya lo da el hecho de que solo un dominio/mail
    # están verificados en la cuenta.
    actions   = ["ses:SendEmail", "ses:SendRawEmail"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda_leads" {
  name   = "${var.project_name}-leads-permissions"
  role   = aws_iam_role.lambda_leads.id
  policy = data.aws_iam_policy_document.lambda_leads_permissions.json
}
