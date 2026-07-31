// Lambda del formulario de contacto - TICKET Fase 2
//
// Flujo: recibe el POST del formulario, valida campos obligatorios,
// guarda el lead en DynamoDB (fuente de verdad, nunca se pierde),
// y en un segundo paso intenta mandar el mail de aviso por SES.
// Si SES falla, el lead ya está guardado igual - no se pierde el pedido.

const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand } = require("@aws-sdk/lib-dynamodb");
const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");
const crypto = require("crypto");

const ddbClient = new DynamoDBClient({});
const ddb = DynamoDBDocumentClient.from(ddbClient);
const ses = new SESClient({});

const REQUIRED_FIELDS = ["nombre", "escuela", "localidad", "telefono"];

function jsonResponse(statusCode, body) {
  return {
    statusCode,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  };
}

exports.handler = async (event) => {
  // API Gateway HTTP API (payload v2) manda el body como string JSON
  let data;
  try {
    data = JSON.parse(event.body || "{}");
  } catch (err) {
    return jsonResponse(400, { error: "JSON inválido" });
  }

  // Validación server-side: nunca confiar solo en la validación del navegador,
  // cualquiera puede pegarle directo a este endpoint con curl/Postman.
  const missing = REQUIRED_FIELDS.filter(
    (field) => !data[field] || String(data[field]).trim() === ""
  );
  if (missing.length > 0) {
    return jsonResponse(400, {
      error: `Faltan campos obligatorios: ${missing.join(", ")}`,
    });
  }

  const lead = {
    id: crypto.randomUUID(),
    createdAt: new Date().toISOString(),
    nombre: data.nombre,
    escuela: data.escuela,
    localidad: data.localidad,
    nivel: data.nivel || "No especificado",
    telefono: data.telefono,
    alumnos: data.alumnos || null,
    mensaje: data.mensaje || "",
    estado: "pendiente", // útil para el futuro panel de gestión (Fase 4)
  };

  // Paso 1: persistir. Si esto falla, no seguimos - preferimos devolver
  // error al usuario antes que decirle "listo" sin haber guardado nada.
  try {
    await ddb.send(
      new PutCommand({
        TableName: process.env.LEADS_TABLE,
        Item: lead,
      })
    );
  } catch (err) {
    console.error("Error guardando en DynamoDB", err);
    return jsonResponse(500, {
      error: "No se pudo guardar el pedido. Intentá de nuevo en unos minutos.",
    });
  }

  // Paso 2: notificar por mail. Si esto falla, NO devolvemos error al
  // usuario - el pedido ya está a salvo en la base de datos, solo
  // registramos el problema en los logs para investigarlo después.
  try {
    await ses.send(
      new SendEmailCommand({
        Source: process.env.SENDER_EMAIL,
        Destination: { ToAddresses: [process.env.RECIPIENT_EMAIL] },
        Message: {
          Subject: { Data: `Nuevo pedido de presupuesto - ${lead.escuela}` },
          Body: {
            Text: {
              Data: [
                "Nueva solicitud de presupuesto recibida desde la web:",
                "",
                `Nombre: ${lead.nombre}`,
                `Institución: ${lead.escuela}`,
                `Localidad: ${lead.localidad}`,
                `Nivel: ${lead.nivel}`,
                `Teléfono: ${lead.telefono}`,
                `Alumnos estimados: ${lead.alumnos || "No especificado"}`,
                `Mensaje: ${lead.mensaje || "(sin mensaje adicional)"}`,
                "",
                `ID de referencia: ${lead.id}`,
              ].join("\n"),
            },
          },
        },
      })
    );
  } catch (err) {
    console.error("Error enviando email vía SES (lead ya guardado igual)", err);
  }

  return jsonResponse(200, { ok: true, id: lead.id });
};
