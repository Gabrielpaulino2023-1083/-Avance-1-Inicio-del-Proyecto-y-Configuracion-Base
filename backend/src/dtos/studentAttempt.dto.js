const num = (v) => (v === null || v === undefined ? null : Number(v));

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

module.exports = { toActivityResponse, toQuestionnaireResponse };