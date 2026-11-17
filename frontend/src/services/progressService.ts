// Detalle del progreso. En modo real: horas por día desde /minutos y dominio
// por tema desde /resultados. En modo simulado se usan datos de ejemplo.
import { USE_MOCK } from "./http";
import {
  listEnrollments,
  listMinutes,
  listResults,
  loadTopicNames,
} from "./learningService";

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

// Mismos umbrales que el motor adaptativo: >= 85 dominado, < 60 reforzar.
function statusFor(mastery: number): TopicProgress["status"] {
  if (mastery >= 85) return "strong";
  if (mastery >= 60) return "steady";
  return "reinforce";
}

const dayKey = (d: Date) => d.toLocaleDateString("en-CA");

async function apiDetail(token: string): Promise<ProgressDetail> {
  const enrollments = await listEnrollments(token);

  // Últimos 7 días, el más antiguo primero. El backend toma "hasta" como
  // límite exclusivo, por eso se pide hasta mañana para incluir hoy.
  const today = new Date();
  const days = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(today);
    d.setDate(today.getDate() - (6 - i));
    return d;
  });
  const tomorrow = new Date(today);
  tomorrow.setDate(today.getDate() + 1);

  const data = await Promise.all(
    enrollments.map(async (e) => {
      const [minutes, results, names] = await Promise.all([
        listMinutes(token, e.inscripcionId, dayKey(days[0]), dayKey(tomorrow)),
        listResults(token, e.inscripcionId),
        loadTopicNames(token, e.cursoId),
      ]);
      return { minutes, results, names };
    })
  );

  // Los días sin intentos no vienen de la API: se rellenan con 0.
  const minutesByDay = new Map<string, number>();
  const scoresByTopic = new Map<number, { name: string; scores: number[] }>();
  for (const { minutes, results, names } of data) {
    for (const m of minutes) {
      minutesByDay.set(
        m.dia,
        (minutesByDay.get(m.dia) ?? 0) + (m.minutosTranscurridos ?? 0)
      );
    }
    for (const r of results) {
      const score = r.notaAcademicaPorcentaje ?? r.promedioPorcentaje;
      if (score === null) continue;
      const entry = scoresByTopic.get(r.temaId) ?? {
        name: names.get(r.temaId) ?? `Tema ${r.temaId}`,
        scores: [],
      };
      entry.scores.push(score);
      scoresByTopic.set(r.temaId, entry);
    }
  }

  const weeklyHours: WeeklyHour[] = days.map((d) => {
    const label = d
      .toLocaleDateString("es-DO", { weekday: "short" })
      .replace(".", "");
    return {
      day: label.charAt(0).toUpperCase() + label.slice(1),
      hours: Math.round(((minutesByDay.get(dayKey(d)) ?? 0) / 60) * 10) / 10,
    };
  });

  // Dominio del tema = promedio de tus notas en sus actividades.
  const topics: TopicProgress[] = [...scoresByTopic.entries()]
    .map(([id, t]) => {
      const mastery =
        Math.round((t.scores.reduce((a, b) => a + b, 0) / t.scores.length) * 10) /
        10;
      return { id, name: t.name, mastery, status: statusFor(mastery) };
    })
    .sort((a, b) => b.mastery - a.mastery);

  return { weeklyHours, topics };
}

export async function getProgressDetail(
  token: string | null
): Promise<ProgressDetail> {
  if (USE_MOCK || !token) {
    await wait(500);
    return MOCK_DETAIL;
  }
  return apiDetail(token);
}