// Historial de evaluaciones. DATOS DE EJEMPLO: el backend todavía no tiene
// tabla de evaluaciones. Cuando exista, solo se cambia este archivo.

export interface Evaluation {
  id: number;
  title: string;
  topic: string;
  date: string; // AAAA-MM-DD
  score: number; // 0 a 100
  attempts: number;
  errors: number;
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

export async function getEvaluations(): Promise<Evaluation[]> {
  await wait(500);
  return MOCK_EVALUATIONS;
}

export function formatShortDate(date: string): string {
  return new Date(`${date}T00:00:00`).toLocaleDateString("es-DO", {
    day: "numeric",
    month: "short",
  });
}