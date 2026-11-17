// Datos del usuario, basados en la tabla `usuarios` de la base de datos.
export interface User {
  id: number;
  nombre: string;
  apellido: string;
  email: string;
  rol: "ESTUDIANTE" | "DOCENTE" | "ADMINISTRADOR";
}

// Lo que se envía al iniciar sesión.
export interface LoginRequest {
  email: string;
  password: string;
}

// Lo que se espera recibir al iniciar sesión correctamente.
// PROVISIONAL: el contrato real lo debe definir el compañero de Backend.
export interface LoginResponse {
  token: string;
  user: User;
}

// Recomendación generada por el motor adaptativo (Python),
// con los mismos campos que devuelve hoy adaptive-engine/main.py.
export interface Recommendation {
  student_id: number;
  topic: string;
  action: "reinforce_topic" | "increase_difficulty" | "maintain_difficulty";
  difficulty: "reduced" | "increased" | "current";
  reason: string;
  recommendation: string;
}
// Datos que muestra el Dashboard.
// Mientras no exista el endpoint del backend, se alimentan de datos de ejemplo.
export interface ActivityItem {
  id: number;
  kind: "lesson" | "evaluation" | "achievement" | "goal";
  title: string;
  detail: string;
  when: string;
}

export interface DashboardSummary {
  progressPercent: number;
  weeklyChange: number | null;
  modulesCompleted: number;
  modulesPending: number;
  activeCourses: number;
  pendingActivities: number;
  averageScore: number | null;
  studyHours: number;
  trends: StatTrends;
  // null cuando el estudiante aún no tiene intentos calificados.
  recommendation: Recommendation | null;
  evidence: RecommendationEvidence | null;
  // Para pedir la recomendación detallada (paso 3).
  recommendationRef: { inscripcionId: number; temaId: number } | null;
  recentActivity: ActivityItem[];
}

// null = no hay datos para comparar: la pantalla muestra un guion.
export interface StatTrends {
  activeCourses: number | null;
  pendingActivities: number | null;
  averageScore: number | null;
  studyHours: number | null;
}

// Datos que explican por qué el motor hace su recomendación.
export interface RecommendationEvidence {
  mastery: number; // % de dominio del tema
  errors: number;
  attempts: number;
}