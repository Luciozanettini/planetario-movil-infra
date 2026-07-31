output "name_servers" {
  description = "Nameservers de la Hosted Zone. Hay que pegar estos 4 valores en el panel de NIC Argentina (sección 'Servidores DNS' / 'Delegación DNS')."
  value       = aws_route53_zone.primary.name_servers
}

output "cloudfront_domain_name" {
  description = "Dominio técnico de CloudFront (ej: d123abc.cloudfront.net), útil para debug"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "cloudfront_distribution_id" {
  description = "ID de la distribución (distinto del domain name) - necesario para invalidar cache"
  value       = aws_cloudfront_distribution.cdn.id
}

output "site_url" {
  description = "URL final del sitio, una vez propagado el DNS"
  value       = "https://${var.domain_name}"
}

output "leads_api_endpoint" {
  description = "URL del endpoint del formulario. Hay que pegar este valor en la constante CONTACT_API_URL del <script> de site/index.html, y volver a aplicar."
  value       = "${aws_apigatewayv2_api.leads.api_endpoint}/leads"
}
