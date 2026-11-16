// pg devuelve NUMERIC y BIGINT como texto: se convierten a número y se conserva null.
const num = (v) => (v === null || v === undefined ? null : Number(v));

const toResultResponse = (r) => ({
  actividadId: r.actividad_id,
  temaId: r.tema_id,
  moduloId: r.modulo_id,
  titulo: r.titulo,
  finalidad: r.finalidad,
  intentosCalificados: num(r.intentos_calificados),
  promedioPorcentaje: num(r.promedio_porcentaje),
  notaAcademicaPorcentaje: num(r.nota_academica_porcentaje),
  ultimaCalificacionEn: r.ultima_calificacion_en
});

const toRecentActivityResponse = (r) => ({
  intentoId: r.intento_id,
  actividadId: r.actividad_id,
  temaId: r.tema_id,
  titulo: r.titulo,
  estado: r.estado,
  ocurridoEn: r.ocurrido_en,
  puntajePorcentaje: num(r.puntaje_porcentaje)
});

const toProgressResponse = (r) => ({
  temaId: r.tema_id,
  moduloId: r.modulo_id,
  actividadesPublicadas: num(r.actividades_publicadas),
  actividadesCalificadas: num(r.actividades_calificadas),
  progresoPorcentaje: num(r.progreso_porcentaje),
  completado: r.completado
});

const toMinutesResponse = (r) => ({
  dia: r.dia_local,
  intentosEntregados: num(r.intentos_entregados),
  minutosTranscurridos: num(r.minutos_transcurridos)
});

module.exports = { toResultResponse, toRecentActivityResponse, toProgressResponse, toMinutesResponse };