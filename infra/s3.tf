# Bucket 100% privado. No usamos "S3 website hosting" público (el patrón viejo
# que vas a ver en muchos tutoriales) porque expone el bucket directo a internet
# sin HTTPS nativo. En su lugar, el bucket queda cerrado y solo CloudFront
# puede leerlo, vía Origin Access Control (ver cloudfront.tf y la policy abajo).
resource "aws_s3_bucket" "site" {
  bucket = "${var.project_name}-site"
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versionado: si algún día se sube un index.html corrupto o se borra por error,
# se puede restaurar la versión anterior sin depender de backups externos.
resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Policy que le da permiso de lectura a CloudFront (y SOLO a CloudFront,
# gracias a la condición sobre el ARN exacto de esta distribución) sobre
# los objetos del bucket. Este es el mecanismo moderno (OAC) que reemplaza
# al viejo Origin Access Identity (OAI).
data "aws_iam_policy_document" "site_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site_policy.json
}

# Sube el index.html directo por Terraform. Es una solución rápida para esta
# fase (Fase 1). En la Fase 3 (CI/CD) esto se reemplaza por un paso de GitHub
# Actions que sincroniza toda la carpeta site/ con aws s3 sync, más flexible
# para múltiples archivos (imágenes, CSS separado, etc).
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  source       = var.landing_page_file
  etag         = filemd5(var.landing_page_file) # fuerza el re-upload si el archivo cambia
  content_type = "text/html"
}
