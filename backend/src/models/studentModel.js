const pool = require('../config/db');

// Cursos en los que el estudiante tiene una inscripción ACTIVA
const findActiveCourses = async (studentId) => {
  const { rows } = await pool.query(
    `SELECT c.id AS "cursoId",
            c.nombre,
            s.codigo AS seccion,
            i.estado,
            i.inscrito_en AS "inscritoEn"
     FROM inscripciones i
     JOIN secciones s ON s.id = i.seccion_id
     JOIN ediciones_curso e ON e.id = i.edicion_id
     JOIN cursos c ON c.id = e.curso_id
     WHERE i.estudiante_id = $1 AND i.estado = 'ACTIVA'
     ORDER BY i.inscrito_en DESC`,
    [studentId]
  );
  return rows;
};

// Métricas reales calculadas desde actividades, intentos y resultados.
const findRealMetrics = async (studentId) => {
  const { rows } = await pool.query(
    `SELECT
       -- Actividades publicadas y vigentes, sin intento entregado o calificado
       (SELECT COUNT(*)
        FROM actividades a
        JOIN inscripciones i ON i.seccion_id = a.seccion_id
        WHERE i.estudiante_id = $1
          AND i.estado = 'ACTIVA'
          AND a.estado = 'PUBLICADO'
          AND a.disponible_desde <= clock_timestamp()
          AND (a.disponible_hasta IS NULL OR a.disponible_hasta > clock_timestamp())
          AND NOT EXISTS (
            SELECT 1 FROM intentos it
            WHERE it.actividad_id = a.id
              AND it.inscripcion_id = i.id
              AND it.estado IN ('ENTREGADO', 'CALIFICADO')
          )
       )::int AS "actividadesPendientes",

       -- Promedio de notas académicas (solo evaluaciones calificadas)
       (SELECT ROUND(AVG(nota_academica_porcentaje), 2)
        FROM resultados_actividades
        WHERE estudiante_id = $1
          AND nota_academica_porcentaje IS NOT NULL
       ) AS "notaPromedio",

       -- Tiempo dentro de actividades (entrega - inicio), en horas
       (SELECT ROUND(COALESCE(SUM(EXTRACT(EPOCH FROM (it.entregado_en - it.iniciado_en))), 0) / 3600.0, 1)
        FROM intentos it
        JOIN inscripciones i ON i.id = it.inscripcion_id
        WHERE i.estudiante_id = $1
          AND it.entregado_en IS NOT NULL
       ) AS "horasEstudio"`,
    [studentId]
  );

  const r = rows[0];
  return {
    actividadesPendientes: r.actividadesPendientes,
    notaPromedio: r.notaPromedio === null ? null : Number(r.notaPromedio),
    horasEstudio: Number(r.horasEstudio)
  };
};

// ¿El docente está asignado a alguna sección donde el estudiante tiene inscripción?
const isTeacherOfStudent = async (teacherId, studentId) => {
  const { rows } = await pool.query(
    `SELECT 1
     FROM seccion_docentes sd
     JOIN inscripciones i ON i.seccion_id = sd.seccion_id
     WHERE sd.usuario_id = $1
       AND sd.activo = TRUE
       AND i.estudiante_id = $2
     LIMIT 1`,
    [teacherId, studentId]
  );
  return rows.length > 0;
};

module.exports = { findActiveCourses, findRealMetrics, isTeacherOfStudent };