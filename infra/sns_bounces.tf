resource "aws_sns_topic" "escuelas_bounces" {
  name = "planetario-movil-escuelas-bounces"
}

resource "aws_sns_topic_subscription" "bounces_lambda" {
  topic_arn = aws_sns_topic.escuelas_bounces.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.bounce_handler.arn
}

resource "aws_lambda_permission" "sns_invoke_bounce_handler" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bounce_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.escuelas_bounces.arn
}

# Conecta el dominio verificado con el topic: cualquier mail que rebote
# o reciba una queja, sin importar qué Lambda lo mandó, notifica acá.
resource "aws_ses_identity_notification_topic" "bounce" {
  topic_arn                = aws_sns_topic.escuelas_bounces.arn
  notification_type        = "Bounce"
  identity                 = aws_ses_domain_identity.domain.domain
  include_original_headers = true
}

resource "aws_ses_identity_notification_topic" "complaint" {
  topic_arn                = aws_sns_topic.escuelas_bounces.arn
  notification_type        = "Complaint"
  identity                 = aws_ses_domain_identity.domain.domain
  include_original_headers = true
}