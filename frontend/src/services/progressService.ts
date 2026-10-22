// Detalle del progreso que el backend todavía no entrega:
// horas por día y dominio por tema. Son DATOS DE EJEMPLO.
// Cuando existan las tablas de interacciones y temas, solo se cambia
// este archivo; las pantallas no se tocan.

export interface WeeklyHour {
  day: string;
  hours: number;
}

export interface TopicProgress {
  id: number;
  name: string;
  mastery: number; // 0 a 100
  status: "strong" | "steady" | "reinforce";
}

export interface ProgressDetail {
  weeklyHours: WeeklyHour[];
  topics: TopicProgress[];
}

const MOCK_DETAIL: ProgressDetail = {
  weeklyHours: [
    { day: "Lun", hours: 3.5 },
    { day: "Mar", hours: 5 },
    { day: "Mié", hours: 4 },
    { day: "Jue", hours: 6.5 },
    { day: "Vie", hours: 3 },
    { day: "Sáb", hours: 7.5 },
    { day: "Dom", hours: 2.5 },
  ],
  topics: [
    { id: 1, name: "Consultas con SELECT y WHERE", mastery: 92, status: "strong" },
    { id: 2, name: "Normalización", mastery: 85, status: "strong" },
    { id: 3, name: "Funciones de agregación", mastery: 78, status: "steady" },
    { id: 4, name: "Subconsultas", mastery: 64, status: "steady" },
    { id: 5, name: "SQL JOIN", mastery: 53, status: "reinforce" },
  ],
};

function wait(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function getProgressDetail(): Promise<ProgressDetail> {
  await wait(500);
  return MOCK_DETAIL;
}