import type { DashboardSummary } from "../types";

const API_URL = import.meta.env.VITE_API_URL ?? "http://localhost:3000/api";
const USE_MOCK = import.meta.env.VITE_USE_MOCK !== "false";

// DATOS DE EJEMPLO: el backend todavía no tiene endpoint de progreso.
// La recomendación sigue el formato real que devuelve adaptive-engine/main.py.
const MOCK_SUMMARY: DashboardSummary = {
  progressPercent: 72,
  weeklyChange: 5,
  modulesCompleted: 18,
  modulesPending: 7,
  activeCourses: 4,
  pendingActivities: 8,
  averageScore: 86,
  studyHours: 32,
    trends: {
    activeCourses: 1,
    pendingActivities: -2,
    averageScore: 3,
    studyHours: 6,
  },
  recommendation: {
    student_id: 1,
    topic: "SQL JOIN",
    action: "reinforce_topic",
    difficulty: "reduced",
    reason:
      "Puntuación promedio: 53.3%; errores acumulados: 9; intentos promedio: 3.0.",
    recommendation:
      "Se recomienda reforzar el tema SQL JOIN con explicaciones y ejercicios guiados. Conviene ofrecer material complementario con una explicación diferente.",
  },
  recentActivity: [
    {
      id: 1,
      kind: "lesson",
      title: "Lección completada",
      detail: "Consultas con SELECT y WHERE",
      when: "Hoy",
    },
    {
      id: 2,
      kind: "evaluation",
      title: "Evaluación realizada",
      detail: "SQL JOIN: 55% de aciertos",
      when: "Ayer",
    },
    {
      id: 3,
      kind: "achievement",
      title: "Logro obtenido",
      detail: "Cinco días seguidos de estudio",
      when: "Hace 2 días",
    },
    {
      id: 4,
      kind: "goal",
      title: "Próximo objetivo",
      detail: "Reforzar SQL JOIN y repetir la evaluación",
      when: "Esta semana",
    },
  ],
};

function wait(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function mockSummary(): Promise<DashboardSummary> {
  await wait(600);
  return MOCK_SUMMARY;
}

async function apiSummary(token: string): Promise<DashboardSummary> {
  // PROVISIONAL: este endpoint aún no existe; lo deben definir Backend y Motor.
  const response = await fetch(`${API_URL}/students/me/summary`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!response.ok) {
    throw new Error("No se pudo cargar el resumen del estudiante.");
  }
  return response.json();
}

export function getDashboardSummary(
  token: string | null
): Promise<DashboardSummary> {
  if (USE_MOCK || !token) return mockSummary();
  return apiSummary(token);
}