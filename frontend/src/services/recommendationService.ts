import type { Recommendation, RecommendationEvidence } from "../types";

// Recomendación SIMULADA para la pantalla de ejemplo (modo VITE_USE_MOCK).
// Con la API real, el estudiante usa AttemptPanel, que pide la recomendación
// a POST /mis-inscripciones/:inscripcionId/temas/:temaId/recomendacion
// (ver getTopicRecommendation en learningService.ts).

// Lo que el estudiante hizo en el ejercicio.
export interface ExerciseResult {
  topic: string;
  attempts: number;
  errors: number;
  seconds: number;
}

export interface RecommendationResult {
  recommendation: Recommendation;
  evidence: RecommendationEvidence;
}

function wait(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// Datos que explican la recomendación (calculados con este ejercicio).
function buildEvidence(r: ExerciseResult): RecommendationEvidence {
  return {
    mastery: r.attempts > 0 ? Math.round(1000 / r.attempts) / 10 : 0,
    errors: r.errors,
    attempts: r.attempts,
  };
}

function textFor(action: Recommendation["action"], topic: string): string {
  if (action === "reinforce_topic") {
    return `Se recomienda reforzar el tema ${topic} con explicaciones y ejercicios guiados. Conviene ofrecer material complementario con una explicación diferente.`;
  }
  if (action === "increase_difficulty") {
    return `Dominas el tema ${topic}. Se recomienda aumentar la dificultad con ejercicios más retadores.`;
  }
  return `Vas bien en el tema ${topic}. Se recomienda mantener la dificultad actual y seguir practicando.`;
}

function build(
  r: ExerciseResult,
  studentId: number,
  action: Recommendation["action"],
  difficulty: Recommendation["difficulty"]
): RecommendationResult {
  const evidence = buildEvidence(r);
  return {
    evidence,
    recommendation: {
      student_id: studentId,
      topic: r.topic,
      action,
      difficulty,
      reason: `Dominio: ${evidence.mastery}%; errores: ${evidence.errors}; intentos: ${evidence.attempts}.`,
      recommendation: textFor(action, r.topic),
    },
  };
}

// Reglas sencillas parecidas a las del motor adaptativo (basado en reglas).
export async function getRecommendation(
  _token: string | null,
  studentId: number | null,
  result: ExerciseResult
): Promise<RecommendationResult> {
  await wait(800);
  const id = studentId ?? 1;
  if (result.errors >= 2) {
    return build(result, id, "reinforce_topic", "reduced");
  }
  if (result.errors === 0) {
    return build(result, id, "increase_difficulty", "increased");
  }
  return build(result, id, "maintain_difficulty", "current");
}