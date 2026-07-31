# Las métricas de facturación de AWS SOLO existen en us-east-1, sin importar
# en qué región esté el resto de tu infraestructura - por eso usamos el
# provider alias que ya definimos para el certificado ACM.
#
# IMPORTANTE: antes de que esta alarma funcione, hay que activar
# "Receive Billing Alerts" en Billing Preferences (consola de AWS,
# paso manual, una sola vez - no se puede hacer por Terraform).

resource "aws_sns_topic" "billing_alerts" {
  provider = aws.us_east_1
  name     = "${var.project_name}-billing-alerts"
}

resource "aws_sns_topic_subscription" "billing_email" {
  provider  = aws.us_east_1
  topic_arn = aws_sns_topic.billing_alerts.arn
  protocol  = "email"
  endpoint  = var.billing_alert_email
}

resource "aws_cloudwatch_metric_alarm" "billing" {
  provider = aws.us_east_1

  alarm_name          = "${var.project_name}-billing-threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600 # 6 horas - esta métrica no se actualiza más seguido que eso
  statistic           = "Maximum"
  threshold           = var.billing_alert_threshold_usd
  alarm_description   = "Avisa si el gasto estimado del mes supera el umbral definido"

  dimensions = {
    Currency = "USD"
  }

  alarm_actions = [aws_sns_topic.billing_alerts.arn]
}
