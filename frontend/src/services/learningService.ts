import { request } from "./http";

// Las rutas /mis-* del backend responden { success, data }.
interface Envelope<T> {
  success: boolean;
  data: T;
}

// GET /api/mis-cursos: de aquí sale el inscripcionId.
export interface Enrollment {
  inscripcionId: number;
  cursoId: number;
  codigo: string;
  curso: string;
  edicionId: number;
  seccionId: number;
  seccion: string;
}

// GET /api/mis-inscripciones/:id/actividad-reciente
export interface RecentAttempt {
  intentoId: number;
  actividadId: number;
  temaId: number;
  titulo: string;
  estado: "ENTREGADO" | "CALIFICADO";
  ocurridoEn: string;
  puntajePorcentaje: number | null;
}

export async function listEnrollments(token: string): Promise<Enrollment[]> {
  const res = await request<Envelope<Enrollment[]>>("/mis-cursos", { token });
  return res.data;
}

export async function listRecentAttempts(
  token: string,
  inscripcionId: number,
  limite = 10
): Promise<RecentAttempt[]> {
  const res = await request<Envelope<RecentAttempt[]>>(
    `/mis-inscripciones/${inscripcionId}/actividad-reciente?limite=${limite}`,
    { token }
  );
  return res.data;
}
// ---------- Contenido publicado ----------

export interface ModuleApi {
  id: number;
  cursoId: number;
  nombre: string;
  descripcion: string;
  orden: number;
  estado: string;
  totalTemas: number;
}

export interface TopicApi {
  id: number;
  moduloId: number;
  nombre: string;
  descripcion: string;
  orden: number;
  estado: string;
}

export interface ActivityApi {
  id: number;
  temaId: number;
  titulo: string;
  finalidad: string;
  metodoCalificacion: string;
  maxIntentos: number | null;
  duracionMinutos: number | null;
  disponibleDesde: string;
  disponibleHasta: string | null;
  estado: string;
  disponibleAhora: boolean;
}

export async function listModules(
  token: string,
  cursoId: number
): Promise<ModuleApi[]> {
  const res = await request<Envelope<ModuleApi[]>>(
    `/mis-cursos/${cursoId}/modulos`,
    { token }
  );
  return res.data;
}

export async function listTopics(
  token: string,
  moduloId: number
): Promise<TopicApi[]> {
  const res = await request<Envelope<TopicApi[]>>(
    `/mis-modulos/${moduloId}/temas`,
    { token }
  );
  return res.data;
}

export async function listActivities(
  token: string,
  inscripcionId: number,
  temaId: number
): Promise<ActivityApi[]> {
  const res = await request<Envelope<ActivityApi[]>>(
    `/mis-inscripciones/${inscripcionId}/temas/${temaId}/actividades`,
    { token }
  );
  return res.data;
}

// ---------- Intentos y cuestionario ----------

export interface QuestionOption {
  id: number;
  texto: string;
  orden: number;
}

export interface Question {
  preguntaId: number;
  respuestaId: number;
  orden: number;
  tipo: "SELECCION_UNICA" | "SELECCION_MULTIPLE";
  enunciado: string;
  puntajeMaximo: number | null;
  opciones: QuestionOption[];
  opcionesSeleccionadas: number[];
}

export interface Questionnaire {
  intentoId: number;
  actividadId: number;
  instrucciones: string | null;
  venceEn: string | null;
  preguntas: Question[];
}

export interface AttemptResult {
  intentoId: number;
  actividadId: number;
  estado: string;
  motivoEntrega: string | null;
  puntajeObtenido: number | null;
  puntajeMaximo: number | null;
  porcentaje: number | null;
}

// Inicia un intento (201) y devuelve el cuestionario. El backend nunca
// envía cuál opción es la correcta.
export async function startAttempt(
  token: string,
  inscripcionId: number,
  actividadId: number
): Promise<Questionnaire> {
  const res = await request<Envelope<Questionnaire>>(
    `/mis-inscripciones/${inscripcionId}/actividades/${actividadId}/intentos`,
    { method: "POST", token }
  );
  return res.data;
}

export async function getQuestionnaire(
  token: string,
  intentoId: number
): Promise<Questionnaire> {
  const res = await request<Envelope<Questionnaire>>(
    `/mis-intentos/${intentoId}/cuestionario`,
    { token }
  );
  return res.data;
}

// Guarda la selección de una pregunta (reemplaza la anterior; [] la borra).
export async function saveSelection(
  token: string,
  respuestaId: number,
  opciones: number[]
): Promise<void> {
  await request(`/mis-respuestas/${respuestaId}/opciones`, {
    method: "PUT",
    body: { opciones },
    token,
  });
}

// Entrega y califica en el servidor: el frontend no envía notas.
export async function submitAttempt(
  token: string,
  intentoId: number
): Promise<AttemptResult> {
  const res = await request<Envelope<AttemptResult>>(
    `/mis-intentos/${intentoId}/entrega`,
    { method: "POST", token }
  );
  return res.data;
}

// ---------- Recomendación por inscripción y tema ----------

export interface TopicRecommendation {
  inscripcionId: number;
  temaId: number;
  tema: string;
  accion: string;
  dificultad: string;
  recomendacion: string;
  mastery: number;
  errors: number;
  attempts: number;
}

export async function getTopicRecommendation(
  token: string,
  inscripcionId: number,
  temaId: number
): Promise<TopicRecommendation> {
  const res = await request<Envelope<TopicRecommendation>>(
    `/mis-inscripciones/${inscripcionId}/temas/${temaId}/recomendacion`,
    { method: "POST", token }
  );
  return res.data;
}


// ---------- Resultados, minutos y nombres de temas ----------

// GET /api/mis-inscripciones/:id/resultados (una fila por actividad)
export interface ResultApi {
  actividadId: number;
  temaId: number;
  moduloId: number;
  titulo: string;
  finalidad: string;
  intentosCalificados: number | null;
  promedioPorcentaje: number | null;
  notaAcademicaPorcentaje: number | null;
  ultimaCalificacionEn: string | null;
}

export async function listResults(
  token: string,
  inscripcionId: number
): Promise<ResultApi[]> {
  const res = await request<Envelope<ResultApi[]>>(
    `/mis-inscripciones/${inscripcionId}/resultados`,
    { token }
  );
  return res.data;
}

// GET /api/mis-inscripciones/:id/minutos (solo vienen los días con intentos)
export interface MinutesDay {
  dia: string; // AAAA-MM-DD
  intentosEntregados: number | null;
  minutosTranscurridos: number | null;
}

export async function listMinutes(
  token: string,
  inscripcionId: number,
  desde: string,
  hasta: string
): Promise<MinutesDay[]> {
  const res = await request<Envelope<MinutesDay[]>>(
    `/mis-inscripciones/${inscripcionId}/minutos?desde=${desde}&hasta=${hasta}`,
    { token }
  );
  return res.data;
}

// Nombre de cada tema publicado del curso, por id.
export async function loadTopicNames(
  token: string,
  cursoId: number
): Promise<Map<number, string>> {
  const modules = await listModules(token, cursoId);
  const lists = await Promise.all(modules.map((m) => listTopics(token, m.id)));
  return new Map(lists.flat().map((t) => [t.id, t.nombre]));
}