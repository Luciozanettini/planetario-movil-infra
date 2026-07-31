# SES necesita verificar que sos dueño del dominio antes de dejarte mandar
# mails "desde" una dirección de ese dominio. Como ya manejamos la Hosted
# Zone por Terraform, este proceso queda 100% automatizado: no hay que ir
# a ningún panel a copiar/pegar nada a mano.

resource "aws_ses_domain_identity" "domain" {
  domain = var.domain_name
}

# Registro TXT que prueba la propiedad del dominio ante SES
resource "aws_route53_record" "ses_verification" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "_amazonses.${var.domain_name}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.domain.verification_token]
}

# Espera activamente a que SES confirme la verificación antes de seguir
resource "aws_ses_domain_identity_verification" "domain" {
  domain     = aws_ses_domain_identity.domain.id
  depends_on = [aws_route53_record.ses_verification]
}

# DKIM: firma criptográfica de los mails salientes. Sin esto, los mails
# que mandes tienen mucha más chance de caer en spam - Gmail y otros
# proveedores grandes lo exigen de facto hoy en día.
resource "aws_ses_domain_dkim" "domain" {
  domain = aws_ses_domain_identity.domain.domain
}

resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = aws_route53_zone.primary.zone_id
  name    = "${aws_ses_domain_dkim.domain.dkim_tokens[count.index]}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.domain.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

# ⚠️ IMPORTANTE - lee esto antes de aplicar:
# Toda cuenta nueva de AWS arranca con SES en "modo sandbox": solo podés
# mandar mails a direcciones que estén también verificadas (no solo el
# dominio de origen, también cada destinatario). Este recurso dispara un
# mail de verificación REAL a la casilla de tu papá - hay que abrirlo y
# hacer clic en el link de confirmación (paso manual, una sola vez).
#
# Cuando quieras que el formulario funcione para cualquier escuela que
# escriba (no solo enviar A tu papá, sino más adelante tal vez responder
# A las escuelas), vas a tener que pedir "producción" de SES desde la
# consola de AWS (Service Quotas / SES > Account dashboard > Request
# production access). Es gratis, pero AWS tarda entre horas y 1-2 días
# en aprobarlo. Para este caso puntual (mandar SIEMPRE al mismo mail de
# tu papá) ni hace falta salir del sandbox.
resource "aws_ses_email_identity" "recipient" {
  email = var.contact_email
}
