// pg devuelve NUMERIC y BIGINT como texto: se convierten a número para Python.
const toEngineInteraction = (r) => ({
  score_percentage: Number(r.score_percentage),
  errors: Number(r.errors),
  attempts: Number(r.attempts),
  repetitions: Number(r.repetitions),
  navigation_count: Number(r.navigation_count),
  study_minutes: Number(r.study_minutes)
});

const round2 = (n) => Math.round(n * 100) / 100;
const avg = (xs) => xs.reduce((a, b) => a + b, 0) / xs.length;

const toRecommendationResult = (engine, interactions, inscripcionId, temaId) => ({
  inscripcionId,
  temaId,
  tema: engine.topic,
  accion: engine.action,
  dificultad: engine.difficulty,
  recomendacion: engine.recommendation,
  // Evidencia que usa la tarjeta del frontend
  mastery: round2(avg(interactions.map((i) => i.score_percentage))),
  errors: interactions.reduce((sum, i) => sum + i.errors, 0),
  attempts: round2(avg(interactions.map((i) => i.attempts)))
});

module.exports = { toEngineInteraction, toRecommendationResult };