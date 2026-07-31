# Certificado TLS para el dominio + www. Emitido específicamente en us-east-1
# (provider alias) porque es el único requisito de región que acepta CloudFront.
resource "aws_acm_certificate" "cert" {
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true # evita downtime si el cert se reemplaza en el futuro
  }
}

# ACM pide crear un registro DNS específico para probar que sos dueño del dominio.
# for_each recorre las validaciones que pide el certificado (una por cada dominio:
# el raíz y el www) y crea el registro correspondiente automáticamente.
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = aws_route53_zone.primary.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# Este recurso no crea nada nuevo: le dice a Terraform "esperá acá hasta que
# el certificado quede validado" antes de seguir con CloudFront. Sin esto,
# Terraform podría intentar usar un certificado que todavía no es válido.
resource "aws_acm_certificate_validation" "cert" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
