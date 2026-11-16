import type { Curso, CursoInput, EstadoCurso } from "../types/course";
import { request, USE_MOCK } from "./http";

// Modo real: /api/cursos del backend (solo ADMINISTRADOR), respuestas { success, data }.
// Modo simulado: datos guardados en el navegador, con las mismas reglas del backend:
// el código no se repite, un curso nace en BORRADOR, y un curso archivado
// no se puede editar ni reactivar. Eliminar es archivar (baja lógica).

const STORAGE_KEY = "adaptativo.cursos";

interface Store {
  cursos: Curso[];
  nextId: number;
}

const now = () => new Date().toISOString();

function seed(): Store {
  const t = now();
  return {
    nextId: 10,
    cursos: [
      { id: 1, codigo: "SQL-101", nombre: "Bases de datos con SQL", descripcion: "Consultas, JOIN y diseño de tablas.", estado: "ACTIVO", creadoEn: t, actualizadoEn: t },
      { id: 2, codigo: "PY-201", nombre: "Programación en Python", descripcion: "Fundamentos y estructuras de datos.", estado: "BORRADOR", creadoEn: t, actualizadoEn: t },
      { id: 3, codigo: "WEB-110", nombre: "Desarrollo web básico", descripcion: "HTML, CSS y primeros pasos con JavaScript.", estado: "ARCHIVADO", creadoEn: t, actualizadoEn: t },
    ],
  };
}

function load(): Store {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) return JSON.parse(raw) as Store;
  } catch {
    /* si el almacenamiento falla, se usan los datos de ejemplo */
  }
  return seed();
}

function save(store: Store) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(store));
  } catch {
    /* sin almacenamiento: los cambios duran mientras la página esté abierta */
  }
}

function wait(ms = 350) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function clean(input: CursoInput): CursoInput {
  const data = {
    codigo: input.codigo.trim(),
    nombre: input.nombre.trim(),
    descripcion: input.descripcion.trim(),
  };
  if (!data.codigo) throw new Error("El código es obligatorio");
  if (!data.nombre) throw new Error("El nombre es obligatorio");
  if (!data.descripcion) throw new Error("La descripción es obligatoria");
  return data;
}

function sameCode(a: string, b: string) {
  return a.toLowerCase() === b.toLowerCase();
}

// ---------- Simulado ----------

async function mockList(): Promise<Curso[]> {
  await wait();
  return [...load().cursos].sort((a, b) => b.id - a.id);
}

async function mockCreate(input: CursoInput): Promise<Curso> {
  await wait();
  const data = clean(input);
  const s = load();
  if (s.cursos.some((c) => sameCode(c.codigo, data.codigo))) {
    throw new Error("Ya existe un curso con ese código");
  }
  const t = now();
  const curso: Curso = { id: s.nextId++, ...data, estado: "BORRADOR", creadoEn: t, actualizadoEn: t };
  s.cursos.push(curso);
  save(s);
  return curso;
}

async function mockUpdate(id: number, input: CursoInput): Promise<Curso> {
  await wait();
  const data = clean(input);
  const s = load();
  const index = s.cursos.findIndex((c) => c.id === id);
  if (index < 0) throw new Error("El curso no existe");
  if (s.cursos[index].estado === "ARCHIVADO") {
    throw new Error("La operación no es válida para el estado actual del curso");
  }
  if (s.cursos.some((c) => c.id !== id && sameCode(c.codigo, data.codigo))) {
    throw new Error("Ya existe un curso con ese código");
  }
  const curso = { ...s.cursos[index], ...data, actualizadoEn: now() };
  s.cursos[index] = curso;
  save(s);
  return curso;
}

async function mockChangeEstado(id: number, estado: EstadoCurso): Promise<Curso> {
  await wait();
  const s = load();
  const index = s.cursos.findIndex((c) => c.id === id);
  if (index < 0) throw new Error("El curso no existe");
  if (s.cursos[index].estado === "ARCHIVADO") {
    throw new Error("La operación no es válida para el estado actual del curso");
  }
  const curso = { ...s.cursos[index], estado, actualizadoEn: now() };
  s.cursos[index] = curso;
  save(s);
  return curso;
}

// ---------- API real ----------

interface Wrapped<T> {
  success: boolean;
  data: T;
}

// ---------- Funciones públicas ----------

export async function listCursos(token: string | null): Promise<Curso[]> {
  if (USE_MOCK) return mockList();
  const res = await request<Wrapped<Curso[]>>("/cursos?limite=100", { token });
  return res.data;
}

export async function createCurso(token: string | null, input: CursoInput): Promise<Curso> {
  if (USE_MOCK) return mockCreate(input);
  const res = await request<Wrapped<Curso>>("/cursos", { method: "POST", body: input, token });
  return res.data;
}

export async function updateCurso(token: string | null, id: number, input: CursoInput): Promise<Curso> {
  if (USE_MOCK) return mockUpdate(id, input);
  const res = await request<Wrapped<Curso>>(`/cursos/${id}`, { method: "PUT", body: input, token });
  return res.data;
}

export async function changeCursoEstado(
  token: string | null,
  id: number,
  estado: "ACTIVO" | "ARCHIVADO"
): Promise<Curso> {
  if (USE_MOCK) return mockChangeEstado(id, estado);
  const res = await request<Wrapped<Curso>>(`/cursos/${id}/estado`, {
    method: "PATCH",
    body: { estado },
    token,
  });
  return res.data;
}