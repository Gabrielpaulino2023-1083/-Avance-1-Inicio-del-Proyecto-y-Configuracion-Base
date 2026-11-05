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

module.exports = { findActiveCourses };