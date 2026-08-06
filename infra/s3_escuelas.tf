resource "aws_s3_bucket" "escuelas_uploads" {
  bucket = "planetario-movil-escuelas-uploads"
}

resource "aws_s3_bucket_public_access_block" "escuelas_uploads" {
  bucket                  = aws_s3_bucket.escuelas_uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "escuelas_uploads" {
  bucket = aws_s3_bucket.escuelas_uploads.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_notification" "escuelas_uploads" {
  bucket = aws_s3_bucket.escuelas_uploads.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.escuelas_importador.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "imports/"
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.s3_invoke_importador]
}
