import type { Recommendation, RecommendationEvidence } from "../types";
import { request, USE_MOCK } from "./http";

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

const ACTIONS: Recommendation["action"][] = [
  "reinforce_topic",
  "increase_difficulty",
  "maintain_difficulty",
];
const DIFFICULTIES: Recommendation["difficulty"][] = [
  "reduced",
  "increased",
  "current",
];

function wait(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// Datos que explican la recomendación (calculados con este ejercicio).
function buildEvidence(r: ExerciseResult): RecommendationEvidence {
  return {
    mastery: r.attempts > 0 ? Math.round((1000 / r.attempts)) / 10 : 0,
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
  difficulty: Recommendation["difficulty"],
    text?: string,
  realEvidence?: RecommendationEvidence
): RecommendationResult {
    const evidence = realEvidence ?? buildEvidence(r);
  return {
    evidence,
    recommendation: {
      student_id: studentId,
      topic: r.topic,
      action,
      difficulty,
      reason: `Dominio: ${evidence.mastery}%; errores: ${evidence.errors}; intentos: ${evidence.attempts}.`,
      recommendation: text ?? textFor(action, r.topic),
    },
  };
}

// ---------- Simulado ----------
// Reglas sencillas parecidas a las del motor adaptativo (basado en reglas).

async function mockRecommendation(
  r: ExerciseResult,
  studentId: number
): Promise<RecommendationResult> {
  await wait(800);
  if (r.errors >= 2) {
    return build(r, studentId, "reinforce_topic", "reduced");
  }
  if (r.errors === 0) {
    return build(r, studentId, "increase_difficulty", "increased");
  }
  return build(r, studentId, "maintain_difficulty", "current");
}

// ---------- API real ----------
// POST /api/students/:id/recommendation  { topic }
// Responde { studentId, tema, accion, dificultad, recomendacion }.

interface RecommendationApi {
  tema?: string;
  accion?: string;
  dificultad?: string;
  recomendacion?: string;
  mastery?: number;
  errors?: number;
  attempts?: number;
}

function isNum(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value);
}

async function apiRecommendation(
  token: string,
  studentId: number,
  r: ExerciseResult
): Promise<RecommendationResult> {
  const body = await request<Record<string, unknown>>(
    `/students/${studentId}/recommendation`,
    { method: "POST", body: { topic: r.topic }, token }
  );
  // Acepta la respuesta directa o envuelta en data / recommendation.
  const data = (body.data ?? body.recommendation ?? body) as RecommendationApi;

  const action = ACTIONS.find((a) => a === data.accion);
  const difficulty = DIFFICULTIES.find((d) => d === data.dificultad);

  // Sin acción, dificultad, texto o evidencia válidos no mostramos nada
  // inventado: se avisa que la respuesta no sirve.
  if (
    !action ||
    !difficulty ||
    typeof data.recomendacion !== "string" ||
    !isNum(data.mastery) ||
    !isNum(data.errors) ||
    !isNum(data.attempts)
  ) {
    throw new Error(
      "El servidor devolvió una respuesta incompleta o inválida."
    );
  }

  return build(r, studentId, action, difficulty, data.recomendacion, {
    mastery: data.mastery,
    errors: data.errors,
    attempts: data.attempts,
  });
}

export function getRecommendation(
  token: string | null,
  studentId: number | null,
  result: ExerciseResult
): Promise<RecommendationResult> {
  if (USE_MOCK || !token || studentId === null) {
    return mockRecommendation(result, studentId ?? 1);
  }
  return apiRecommendation(token, studentId, result);
}