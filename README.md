# Planetario Móvil — Infraestructura Fase 1

Landing page estática servida vía S3 + CloudFront + Route 53 + ACM, todo gestionado por Terraform.

## Orden de ejecución

### 1. Bootstrap (una sola vez, nunca más)

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

Esto crea el bucket S3 y la tabla DynamoDB donde va a vivir el **state** de Terraform. Guardá el nombre de bucket que te imprime al final.

### 2. Configurar el backend

```bash
cd infra
cp backend.hcl.example backend.hcl
# Editá backend.hcl con el nombre de bucket real que te dio el bootstrap
```

### 3. Configurar variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Editá terraform.tfvars si querés cambiar el dominio, región, etc.
```

### 4. Inicializar y aplicar

```bash
terraform init -backend-config=backend.hcl
terraform plan    # revisá SIEMPRE qué va a crear antes de aplicar
terraform apply
```

### 5. Delegar el DNS en NIC Argentina

Al terminar el `apply`, correé:

```bash
terraform output name_servers
```

Vas a ver algo como:

```
[
  "ns-123.awsdns-45.com",
  "ns-456.awsdns-67.net",
  "ns-789.awsdns-89.org",
  "ns-012.awsdns-01.co.uk",
]
```

Entrá al panel de **NIC Argentina** (nic.ar), a la gestión de `planetariomendoza.com.ar`, buscá la sección de **"Servidores DNS" / "Delegación"**, y reemplazá lo que haya por estos 4 valores exactos (sin la coma final, sin corchetes).

La propagación puede tardar de minutos a 24-48hs. El certificado ACM se valida solo apenas el DNS propague — no hace falta hacer nada más.

### 6. Verificar

```bash
terraform output site_url
```

Y probá abrirlo en el navegador una vez propagado el DNS.

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

## Fase 2 — Formulario funcional (Lambda + API Gateway + DynamoDB + SES)

Después del primer `terraform apply` (Fase 1) exitoso, para activar Fase 2:

### 1. Verificar el mail de destino

`terraform apply` va a disparar un mail real de verificación a `contact_email`
(por defecto `xxxxxxx@gmail.com`, ver `variables.tf`). **Alguien
tiene que abrir ese mail y hacer clic en el link de confirmación** — sin eso,
SES no va a poder enviar notificaciones a esa casilla mientras la cuenta
esté en modo sandbox.

### 2. Aplicar la infraestructura nueva

```bash
cd infra
terraform apply
```

Vas a ver de más recursos nuevos: DynamoDB, la Lambda, API Gateway, y los
registros de verificación de SES en Route 53.

### 3. Conectar el formulario al endpoint real

Al terminar, tomá el valor de:

```bash
terraform output leads_api_endpoint
```

Y pegalo en `site/index.html`, reemplazando esta línea dentro del `<script>`:

```js
const CONTACT_API_URL = "REEMPLAZAR_CON_TERRAFORM_OUTPUT_leads_api_endpoint";
```

### 4. Volver a aplicar para subir el HTML actualizado

```bash
terraform apply
```

Esto sube el `index.html` con la URL correcta ya adentro (Terraform detecta
el cambio por el hash del archivo).

### 5. Invalidar la cache de CloudFront

CloudFront cachea el `index.html` hasta 1 hora (`default_ttl` en
`cloudfront.tf`). Para que el cambio se vea al instante sin esperar:

```bash
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*"
```

*(Este paso manual es justo el tipo de cosa que la Fase 3 - CI/CD - automatiza:
un pipeline que sube el HTML Y invalida la cache en un solo paso, sin
intervención manual.)*

## ⚠️ Riesgos y consideraciones

- **Costo estimado:** con este volumen de tráfico (landing informativa, sin backend todavía), esto entra casi enteramente en el free tier de S3/CloudFront/Route53. El único costo fijo es la Hosted Zone de Route 53 (~0.50 USD/mes) y el dominio que ya pagaste en NIC Argentina.
- **`terraform destroy` no borra el dominio**: solo borra la Hosted Zone y el resto de la infraestructura AWS. El dominio en NIC Argentina sigue siendo tuyo, tendrías que volver a delegar el DNS si recreás la infra.
- **La actualización del `index.html` hoy se hace vía `terraform apply`**: es aceptable para esta fase, pero cuando llegue la Fase 3 (CI/CD), lo correcto es que un pipeline de GitHub Actions haga `aws s3 sync` y una invalidación de CloudFront, sin pasar por Terraform en cada cambio de contenido.
- **No hay WAF ni rate limiting**: para una landing informativa de bajo tráfico no es prioritario, pero si en el futuro se agrega el formulario conectado a un backend (Fase 2), conviene reevaluar.

## Próximos pasos sugeridos

1. Correr el bootstrap y el primer `apply`
2. Delegar DNS en NIC Argentina
3. Verificar que el sitio cargue con HTTPS válido
4. Ticket siguiente: Fase 2 — Lambda + API Gateway + DynamoDB + SES para el formulario de contacto
