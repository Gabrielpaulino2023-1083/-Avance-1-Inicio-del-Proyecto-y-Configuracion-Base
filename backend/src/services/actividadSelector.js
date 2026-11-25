'use strict';

// Selector de la actividad sugerida (propuesto por Jeison en
// database/docs/ejemplos/seleccion_actividad.cjs). Módulo puro: sin Express,
// sin credenciales y sin escrituras.
// Las filas DEBEN proceder de listar_candidatas_actividad(actor del JWT, inscripción, tema, referencia).
const NIVELES = ['BAJA', 'MEDIA', 'ALTA'];

function seleccionarActividad(filas, ajuste) {
  if (!['reduced', 'current', 'increased'].includes(ajuste)) {
    throw new TypeError('Ajuste del motor desconocido; no seleccionar silenciosamente.');
  }
  if (!Array.isArray(filas)) throw new TypeError('Se esperaba un arreglo de candidatas.');
  if (filas.length === 0) return null;
  const primera = filas[0];
  const referencia = NIVELES.indexOf(primera.dificultad_referencia);
  if (referencia < 0) throw new TypeError('Referencia sin dificultad valida.');
  if (!Number.isInteger(primera.actividad_referencia_id) || primera.actividad_referencia_id <= 0) {
    throw new TypeError('Identificador de referencia invalido.');
  }
  for (const f of filas) {
    if (!NIVELES.includes(f.dificultad) || !Number.isInteger(f.actividad_id) || f.actividad_id <= 0 ||
        f.actividad_referencia_id !== primera.actividad_referencia_id ||
        f.dificultad_referencia !== primera.dificultad_referencia) {
      throw new TypeError('Candidatas invalidas o con contextos de referencia mezclados.');
    }
  }
  const salto = ajuste === 'reduced' ? -1 : ajuste === 'increased' ? 1 : 0;
  const objetivo = Math.max(0, Math.min(2, referencia + salto));
  const esRepeticion = f => f.actividad_id === primera.actividad_referencia_id;
  // Prioridad acordada para revision: otra actividad, luego nivel objetivo,
  // distancia, nivel inferior en empate e ID. No modifica el arreglo recibido.
  const ordenadas = [...filas].sort((a, b) =>
    Number(esRepeticion(a)) - Number(esRepeticion(b)) ||
    Math.abs(NIVELES.indexOf(a.dificultad) - objetivo) - Math.abs(NIVELES.indexOf(b.dificultad) - objetivo) ||
    NIVELES.indexOf(a.dificultad) - NIVELES.indexOf(b.dificultad) ||
    a.actividad_id - b.actividad_id
  );
  const elegida = ordenadas[0];
  return {
    actividadId: elegida.actividad_id,
    titulo: elegida.titulo,
    dificultad: elegida.dificultad,
    dificultadObjetivo: NIVELES[objetivo],
    coincideNivel: elegida.dificultad === NIVELES[objetivo],
    esRepeticion: esRepeticion(elegida),
    actividadReferenciaId: primera.actividad_referencia_id,
  };
}

module.exports = { seleccionarActividad };