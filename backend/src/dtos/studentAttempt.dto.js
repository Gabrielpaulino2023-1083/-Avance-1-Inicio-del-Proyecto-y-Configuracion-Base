const num = (v) => (v === null || v === undefined ? null : Number(v));
const { z } = require('zod');

const selectionBodyDto = z.object({
  opciones: z.array(z.coerce.number().int().positive()).max(50)
});

const toActivityResponse = (a) => ({
  id: a.id,
  seccionId: a.seccion_id,
  temaId: a.tema_id,
  titulo: a.titulo,
  finalidad: a.finalidad,
  metodoCalificacion: a.metodo_calificacion,
  maxIntentos: a.max_intentos,
  duracionMinutos: a.duracion_minutos,
  disponibleDesde: a.disponible_desde,
  disponibleHasta: a.disponible_hasta,
  estado: a.estado,
  disponibleAhora: a.disponible_ahora
});

// El cuestionario nunca incluye es_correcta ni explicaciones: la base ya las excluye.
const toQuestionnaireResponse = (rows) => ({
  intentoId: rows[0].intento_id,
  actividadId: rows[0].actividad_id,
  instrucciones: rows[0].instrucciones,
  venceEn: rows[0].vence_en,
  preguntas: rows.map((r) => ({
    preguntaId: r.pregunta_id,
    respuestaId: r.respuesta_id,
    orden: r.orden,
    tipo: r.tipo,
    enunciado: r.enunciado,
    puntajeMaximo: num(r.puntaje_maximo),
    opciones: r.opciones,
    opcionesSeleccionadas: r.opciones_seleccionadas
  }))
});

const toAttemptResultResponse = (i) => {
  const obtenido = num(i.puntaje_obtenido);
  const maximo = num(i.puntaje_maximo);
  return {
    intentoId: i.id,
    actividadId: i.actividad_id,
    estado: i.estado,
    motivoEntrega: i.motivo_entrega,
    entregadoEn: i.entregado_en,
    calificadoEn: i.calificado_en,
    puntajeObtenido: obtenido,
    puntajeMaximo: maximo,
    porcentaje: obtenido !== null && maximo ? Math.round((obtenido * 10000) / maximo) / 100 : null
  };
};

module.exports = { toActivityResponse, toQuestionnaireResponse, selectionBodyDto, toAttemptResultResponse };