const { z } = require('zod');

const estado = z.enum(['BORRADOR', 'PUBLICADO', 'ARCHIVADO'], {
  message: 'El estado debe ser BORRADOR, PUBLICADO o ARCHIVADO'
});

const contentBodyDto = z.object({
  nombre: z.string().trim().min(1, 'El nombre no puede estar vacío').max(150),
  descripcion: z.string().trim().min(1, 'La descripción no puede estar vacía').max(1000),
  orden: z.coerce.number().int('El orden debe ser un entero').min(1, 'El orden debe ser mayor que 0'),
  estado: estado.optional(),
  cursoId: z.coerce.number().int().min(1).optional()
});

const contentStatusDto = z.object({ estado });

const toModuleResponse = (m) => ({
  id: m.id,
  cursoId: m.curso_id,
  nombre: m.nombre,
  descripcion: m.descripcion,
  orden: m.orden,
  estado: m.estado,
  totalTemas: Number(m.total_temas),
  actualizadoEn: m.actualizado_en
});

const toTopicResponse = (t) => ({
  id: t.id,
  moduloId: t.modulo_id,
  nombre: t.nombre,
  descripcion: t.descripcion,
  orden: t.orden,
  estado: t.estado,
  actualizadoEn: t.actualizado_en
});

module.exports = { contentBodyDto, contentStatusDto, toModuleResponse, toTopicResponse };