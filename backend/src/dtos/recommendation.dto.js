const { z } = require('zod');

const recommendationDto = z.object({
  topic: z.string().trim().min(1, 'El tema es obligatorio').max(100)
});

const toRecommendationResponse = (r) => ({
  studentId: r.student_id,
  tema: r.topic,
  accion: r.action,
  dificultad: r.difficulty,
  recomendacion: r.recommendation
});

module.exports = { recommendationDto, toRecommendationResponse };