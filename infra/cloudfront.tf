# OAC (Origin Access Control) es el mecanismo moderno (2022+) para que
# CloudFront acceda a un bucket S3 privado con SigV4. Reemplaza al viejo OAI
# que vas a encontrar en tutoriales desactualizados - no lo uses si ves ejemplos
# con "origin_access_identity", eso ya no es la práctica recomendada.
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.domain_name, "www.${var.domain_name}"]

  # PriceClass_100 = solo edge locations de Norteamérica y Europa.
  # Es la opción más barata; para el volumen de tráfico esperado (visitas
  # de escuelas de Mendoza) es más que suficiente, no hace falta pagar
  # por cobertura global (PriceClass_All).
  price_class = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-${aws_s3_bucket.site.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods          = ["GET", "HEAD"]
    target_origin_id        = "s3-${aws_s3_bucket.site.id}"
    viewer_protocol_policy  = "redirect-to-https" # fuerza HTTPS, nunca serví HTTP plano
    compress                = true                 # gzip/brotli automático, páginas más rápidas

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600  # 1 hora de cache por defecto
    max_ttl     = 86400 # 24 horas máximo
  }

  # Si alguien pide una ruta que no existe, servimos igual index.html con
  # status 200. Útil hoy porque la landing es de una sola página, y deja
  # el terreno preparado si en el futuro se agregan más rutas/framework SPA.
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
