variable "domain_name" {
  description = "Dominio raíz registrado en NIC Argentina (ej: planetariomendoza.com.ar)"
  type        = string
}

variable "project_name" {
  description = "Nombre corto del proyecto, usado como prefijo/tag en todos los recursos"
  type        = string
  default     = "planetario-movil"
}

variable "aws_region" {
  description = "Región AWS para recursos regionales (S3, etc). No aplica a ACM: ese va fijo a us-east-1 por requisito de CloudFront, sin importar esta variable."
  type        = string
  default     = "sa-east-1" # São Paulo: la región AWS más cercana a Mendoza
}

variable "landing_page_file" {
  description = "Ruta local al archivo HTML de la landing que se sube a S3"
  type        = string
  default     = "../site/index.html"
}

variable "contact_email" {
  description = "Email donde llegan los pedidos de presupuesto (destinatario final de la notificación)"
  type        = string
  default     = "juanpablozanettini@gmail.com"
}

variable "billing_alert_email" {
  description = "Email que recibe la alarma si el gasto de AWS supera el umbral"
  type        = string
  default     = "juanpablozanettini@gmail.com" # cambiá esto por TU mail si preferís recibirla vos
}

variable "billing_alert_threshold_usd" {
  description = "Umbral en USD a partir del cual se dispara la alarma de billing"
  type        = number
  default     = 5
}
