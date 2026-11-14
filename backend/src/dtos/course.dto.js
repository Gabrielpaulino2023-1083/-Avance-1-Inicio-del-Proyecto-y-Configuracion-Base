const { z } = require('zod');

const courseBodyDto = z.object({
  codigo: z.string().trim().min(1, 'El código es obligatorio').max(50),
  nombre: z.string().trim().min(1, 'El nombre es obligatorio').max(150),
  descripcion: z.string().trim().min(1, 'La descripción es obligatoria').max(1000)
});

const courseStatusDto = z.object({
  estado: z.enum(['ACTIVO', 'ARCHIVADO'], {
    message: 'El estado debe ser ACTIVO o ARCHIVADO'
  })
});

const toCourseResponse = (c) => ({
  id: c.id,
  codigo: c.codigo,
  nombre: c.nombre,
  descripcion: c.descripcion,
  estado: c.estado,
  creadoPor: c.creado_por,
  creadoEn: c.creado_en,
  actualizadoEn: c.actualizado_en
});

module.exports = { courseBodyDto, courseStatusDto, toCourseResponse };