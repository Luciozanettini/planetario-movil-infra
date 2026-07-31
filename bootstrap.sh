#!/usr/bin/env bash
# ============================================================
# BOOTSTRAP - se corre UNA SOLA VEZ, antes del primer terraform init
# ============================================================
#
# Por qué esto no es parte del módulo de Terraform principal:
# el backend remoto (S3 + DynamoDB) tiene que EXISTIR antes de que
# Terraform pueda guardar su propio state ahí. Es el clásico problema
# de "el huevo o la gallina" en IaC: no podés gestionar por Terraform
# el mismo recurso que Terraform necesita para funcionar.
#
# La solución estándar en la industria: este paso se hace una vez,
# a mano o con un script simple como este, y nunca más se vuelve a tocar.
#
# Requisitos: tener aws-cli instalado y configurado (aws configure)
# con credenciales que tengan permisos de crear buckets S3 y tablas DynamoDB.

set -euo pipefail

# CAMBIAR este nombre por algo único a nivel global (los nombres de bucket S3
# son únicos en TODO AWS, no solo en tu cuenta)
BUCKET_NAME="planetario-movil-tfstate-$(date +%s)"
REGION="sa-east-1"
LOCK_TABLE="planetario-movil-tf-locks"

echo "==> Creando bucket de state: $BUCKET_NAME en $REGION"
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

echo "==> Habilitando versionado (permite recuperar un state anterior si algo sale mal)"
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

echo "==> Bloqueando acceso público al bucket de state (contiene info sensible de tu infra)"
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "==> Habilitando encriptación por defecto (SSE-S3)"
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "==> Creando tabla DynamoDB para locking (evita que dos personas apliquen a la vez)"
aws dynamodb create-table \
  --table-name "$LOCK_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"

echo ""
echo "✅ Listo. Ahora completá infra/backend.hcl con:"
echo "   bucket         = \"$BUCKET_NAME\""
echo "   dynamodb_table = \"$LOCK_TABLE\""
echo "   region         = \"$REGION\""
