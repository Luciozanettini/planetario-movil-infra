# La Hosted Zone es el "libro de reglas DNS" del dominio dentro de AWS.
# Al crearla, AWS asigna automáticamente 4 nameservers (ver outputs.tf) que
# hay que pegar en el panel de NIC Argentina para delegar el control del DNS.
resource "aws_route53_zone" "primary" {
  name    = var.domain_name
  comment = "Hosted zone para ${var.project_name} - gestionada por Terraform, no tocar a mano"
}

# Registro A (alias) del dominio raíz -> CloudFront
resource "aws_route53_record" "apex" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

# Mismo alias para el subdominio www, así funcionan ambas variantes
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
