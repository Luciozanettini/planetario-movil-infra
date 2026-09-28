# Planetario Móvil — Infraestructura Fase 1

Landing page estática servida vía S3 + CloudFront + Route 53 + ACM, todo gestionado por Terraform.

## Estructura

```
terraform-planetario/
├── bootstrap.sh              # Paso único: crea el backend remoto
├── site/
│   └── index.html             # La landing page (Fase 1)
└── infra/
    ├── providers.tf           # Terraform + providers (incluye alias us-east-1 para ACM)
    ├── variables.tf
    ├── route53.tf              # Hosted Zone + registros A alias
    ├── acm.tf                  # Certificado + validación DNS automática
    ├── s3.tf                   # Bucket privado + policy + upload del index.html
    ├── cloudfront.tf           # Distribución CDN con OAC
    ├── outputs.tf
    ├── terraform.tfvars.example
    └── backend.hcl.example
```


