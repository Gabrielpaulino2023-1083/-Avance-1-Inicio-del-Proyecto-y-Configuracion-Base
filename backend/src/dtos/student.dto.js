// ---- DTOs de SALIDA ----
const toStudentSummaryResponse = ({ user, courses, metrics }) => ({
  id: user.id,
  nombre: user.nombre,
  apellido: user.apellido,
  email: user.email,
  rol: user.rol,
  cursosActivos: courses.length,
  cursos: courses.map((c) => ({
    cursoId: c.cursoId,
    nombre: c.nombre,
    seccion: c.seccion,
    estado: c.estado
  })),
  porcentajeCompletado: metrics.porcentajeCompletado,
  modulosFinalizados: metrics.modulosFinalizados,
  modulosPendientes: metrics.modulosPendientes,
  actividadesPendientes: metrics.actividadesPendientes,
  notaPromedio: metrics.notaPromedio,
  horasEstudio: metrics.horasEstudio
});

const toProgressResponse = (progress) => ({
  variaciones: progress.variaciones,
  recomendacion: progress.recomendacion
});

module.exports = { toStudentSummaryResponse, toProgressResponse };