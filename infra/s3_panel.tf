resource "aws_s3_object" "panel" {
  bucket       = aws_s3_bucket.site.id
  key          = "panel.html"
  source       = "${path.module}/../site/panel.html"
  etag         = filemd5("${path.module}/../site/panel.html")
  content_type = "text/html"
}
