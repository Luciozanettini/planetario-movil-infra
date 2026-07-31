terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  # Backend remoto: el state NUNCA vive local en un proyecto real.
  # Los valores concretos (nombre del bucket, tabla de locks) se pasan
  # en el momento del init, no se hardcodean acá:
  #   terraform init -backend-config=backend.hcl
  backend "s3" {}
}

# Provider principal: acá viven S3, Route 53, y el resto de recursos regionales
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      ManagedBy   = "terraform"
      Environment = "production"
    }
  }
}

# Provider alias: CloudFront SOLO acepta certificados ACM emitidos en us-east-1,
# sin importar en qué región esté el resto de la infraestructura. Por eso
# necesitamos un segundo provider apuntado a esa región exclusivamente para el ACM.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = var.project_name
      ManagedBy   = "terraform"
      Environment = "production"
    }
  }
}
