import type { ActivityItem, DashboardSummary } from "../types";
import { request, USE_MOCK } from "./http";

// ---------- Datos simulados (modo sin backend) ----------

// La actividad reciente todavía no existe en el backend: se mantiene
// simulada también cuando se usa la API real.
const MOCK_ACTIVITY: ActivityItem[] = [
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
];

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
  evidence: { mastery: 53.3, errors: 9, attempts: 3 },
  recentActivity: MOCK_ACTIVITY,
};

function wait(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function mockSummary(): Promise<DashboardSummary> {
  await wait(600);
  return MOCK_SUMMARY;
}

// ---------- API real (backend de Porfirio) ----------

// GET /api/students/:id
interface StudentSummaryApi {
  student: {
    id: number;
    cursosActivos: number;
    porcentajeCompletado: number;
    modulosFinalizados: number;
    modulosPendientes: number;
    actividadesPendientes: number;
    notaPromedio: number;
    horasEstudio: number;
  };
}

// GET /api/students/:id/progress
interface StudentProgressApi {
  progress: {
    variaciones: {
      porcentajeSemanal: number;
      cursosMes: number;
      actividadesSemana: number;
      notaPuntos: number;
      horasSemana: number;
    };
    recomendacion: {
      tema: string;
      accion: DashboardSummary["recommendation"]["action"];
      dificultad: DashboardSummary["recommendation"]["difficulty"];
      descripcion: string;
      motivo: {
        puntuacionPromedio: number;
        erroresAcumulados: number;
        intentosPromedio: number;
      };
    };
  };
}

// Traduce los campos en español del backend al formato que usan las pantallas.
function toDashboardSummary(
  summary: StudentSummaryApi["student"],
  progress: StudentProgressApi["progress"]
): DashboardSummary {
  const { variaciones: v, recomendacion: r } = progress;

  return {
    progressPercent: summary.porcentajeCompletado,
    weeklyChange: v.porcentajeSemanal,
    modulesCompleted: summary.modulosFinalizados,
    modulesPending: summary.modulosPendientes,
    activeCourses: summary.cursosActivos,
    pendingActivities: summary.actividadesPendientes,
    averageScore: summary.notaPromedio,
    studyHours: summary.horasEstudio,
    trends: {
      activeCourses: v.cursosMes,
      pendingActivities: v.actividadesSemana,
      averageScore: v.notaPuntos,
      studyHours: v.horasSemana,
    },
    recommendation: {
      student_id: summary.id,
      topic: r.tema,
      action: r.accion,
      difficulty: r.dificultad,
      reason: `Puntuación promedio: ${r.motivo.puntuacionPromedio}%; errores acumulados: ${r.motivo.erroresAcumulados}; intentos promedio: ${r.motivo.intentosPromedio}.`,
      recommendation: r.descripcion,
    },
    evidence: {
      mastery: r.motivo.puntuacionPromedio,
      errors: r.motivo.erroresAcumulados,
      attempts: r.motivo.intentosPromedio,
    },
    recentActivity: MOCK_ACTIVITY,
  };
}

async function apiSummary(
  token: string,
  studentId: number
): Promise<DashboardSummary> {
  const [summary, progress] = await Promise.all([
    request<StudentSummaryApi>(`/students/${studentId}`, { token }),
    request<StudentProgressApi>(`/students/${studentId}/progress`, { token }),
  ]);
  return toDashboardSummary(summary.student, progress.progress);
}

export function getDashboardSummary(
  token: string | null,
  studentId: number | null
): Promise<DashboardSummary> {
  if (USE_MOCK || !token || studentId === null) return mockSummary();
  return apiSummary(token, studentId);
}