// Historial de evaluaciones. En modo real viene de /mis-inscripciones/:id/resultados;
// en modo simulado se usan datos de ejemplo.
import { USE_MOCK } from "./http";
import {
  listEnrollments,
  listResults,
  loadTopicNames,
} from "./learningService";

export interface Evaluation {
  id: number;
  title: string;
  topic: string;
  date: string; // AAAA-MM-DD
  score: number; // 0 a 100
  attempts: number;
  // La API no guarda los errores por evaluación: null se muestra como guion.
  errors: number | null;
}

// Nota mínima para considerar un tema dominado.
export const PASSING_SCORE = 70;

const MOCK_EVALUATIONS: Evaluation[] = [
  { id: 1, title: "Consultas básicas", topic: "SELECT y WHERE", date: "2026-09-30", score: 98, attempts: 1, errors: 0 },
  { id: 2, title: "Filtrado y ordenamiento", topic: "ORDER BY", date: "2026-10-02", score: 95, attempts: 1, errors: 1 },
  { id: 3, title: "Normalización", topic: "Formas normales", date: "2026-10-06", score: 92, attempts: 2, errors: 2 },
  { id: 4, title: "Funciones de agregación", topic: "COUNT, SUM y AVG", date: "2026-10-09", score: 90, attempts: 2, errors: 3 },
  { id: 5, title: "Subconsultas", topic: "Subconsultas", date: "2026-10-13", score: 86, attempts: 3, errors: 4 },
  { id: 6, title: "SQL JOIN", topic: "SQL JOIN", date: "2026-10-20", score: 55, attempts: 4, errors: 9 },
];

function wait(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// Fecha local AAAA-MM-DD de un instante.
function localDate(iso: string): string {
  return new Date(iso).toLocaleDateString("en-CA");
}

async function apiEvaluations(token: string): Promise<Evaluation[]> {
  const enrollments = await listEnrollments(token);
  const perEnrollment = await Promise.all(
    enrollments.map(async (e) => {
      const [results, names] = await Promise.all([
        listResults(token, e.inscripcionId),
        loadTopicNames(token, e.cursoId),
      ]);
      return results.flatMap((r): Evaluation[] => {
        const score = r.notaAcademicaPorcentaje ?? r.promedioPorcentaje;
        // Sin nota o sin fecha de calificación no hay evaluación que mostrar.
        if (score === null || !r.ultimaCalificacionEn) return [];
        return [
          {
            id: r.actividadId,
            title: r.titulo,
            topic: names.get(r.temaId) ?? `Tema ${r.temaId}`,
            date: localDate(r.ultimaCalificacionEn),
            score: Math.round(score),
            attempts: r.intentosCalificados ?? 0,
            errors: null,
          },
        ];
      });
    })
  );
  return perEnrollment
    .flat()
    .sort((a, b) => a.date.localeCompare(b.date) || a.id - b.id);
}

export async function getEvaluations(
  token: string | null
): Promise<Evaluation[]> {
  if (USE_MOCK || !token) {
    await wait(500);
    return MOCK_EVALUATIONS;
  }
  return apiEvaluations(token);
}

export function formatShortDate(date: string): string {
  return new Date(`${date}T00:00:00`).toLocaleDateString("es-DO", {
    day: "numeric",
    month: "short",
  });
}