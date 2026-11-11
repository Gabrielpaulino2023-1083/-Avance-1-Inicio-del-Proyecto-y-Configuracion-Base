import type { ContenidoInput, Modulo, Tema } from "../types/curriculum";
import { request, USE_MOCK } from "./http";

// Mientras el backend no tenga endpoints de módulos y temas, el CRUD
// funciona con datos simulados guardados en el navegador (localStorage).
// Las reglas imitan las restricciones de la base de datos (migración 002).

const STORAGE_KEY = "adaptativo.curriculum";
const CURSO_ID = 1;

type StoredModulo = Omit<Modulo, "totalTemas">;

interface Store {
  modulos: StoredModulo[];
  temas: Tema[];
  nextId: number;
}

const now = () => new Date().toISOString();

function seed(): Store {
  const t = now();
  return {
    nextId: 100,
    modulos: [
      { id: 1, cursoId: CURSO_ID, nombre: "Fundamentos de SQL", descripcion: "SELECT, filtros y ordenamiento.", orden: 1, estado: "PUBLICADO", actualizadoEn: t },
      { id: 2, cursoId: CURSO_ID, nombre: "Consultas con JOIN", descripcion: "Combinar tablas con INNER, LEFT y RIGHT JOIN.", orden: 2, estado: "PUBLICADO", actualizadoEn: t },
      { id: 3, cursoId: CURSO_ID, nombre: "Normalización", descripcion: "Formas normales y diseño de tablas.", orden: 3, estado: "BORRADOR", actualizadoEn: t },
    ],
    temas: [
      { id: 10, moduloId: 1, nombre: "Sentencia SELECT", descripcion: "Leer columnas de una tabla.", orden: 1, estado: "PUBLICADO", actualizadoEn: t },
      { id: 11, moduloId: 1, nombre: "Filtros con WHERE", descripcion: "Condiciones y operadores.", orden: 2, estado: "PUBLICADO", actualizadoEn: t },
      { id: 12, moduloId: 2, nombre: "INNER JOIN", descripcion: "Unir filas que coinciden.", orden: 1, estado: "PUBLICADO", actualizadoEn: t },
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

// Mismas reglas que los CHECK de la base de datos.
function validate(input: ContenidoInput) {
  if (!input.nombre.trim()) throw new Error("El nombre no puede estar vacío.");
  if (!input.descripcion.trim()) throw new Error("La descripción no puede estar vacía.");
  if (!Number.isInteger(input.orden) || input.orden < 1) {
    throw new Error("El orden debe ser un número entero mayor que 0.");
  }
}

function clean(input: ContenidoInput): ContenidoInput {
  return { ...input, nombre: input.nombre.trim(), descripcion: input.descripcion.trim() };
}

// ---------- Simulado: módulos ----------

async function mockListModulos(): Promise<Modulo[]> {
  await wait();
  const s = load();
  return s.modulos
    .map((m) => ({ ...m, totalTemas: s.temas.filter((t) => t.moduloId === m.id).length }))
    .sort((a, b) => a.orden - b.orden);
}

async function mockSaveModulo(input: ContenidoInput, id?: number): Promise<Modulo> {
  await wait();
  validate(input);
  const data = clean(input);
  const s = load();

  if (s.modulos.some((m) => m.orden === data.orden && m.id !== id)) {
    throw new Error("Ya existe un módulo con ese orden en el curso.");
  }

  let saved: StoredModulo;
  if (id === undefined) {
    saved = { id: s.nextId++, cursoId: CURSO_ID, ...data, actualizadoEn: now() };
    s.modulos.push(saved);
  } else {
    const index = s.modulos.findIndex((m) => m.id === id);
    if (index < 0) throw new Error("El módulo ya no existe.");
    saved = { ...s.modulos[index], ...data, actualizadoEn: now() };
    s.modulos[index] = saved;
  }
  save(s);
  return { ...saved, totalTemas: s.temas.filter((t) => t.moduloId === saved.id).length };
}

async function mockDeleteModulo(id: number): Promise<void> {
  await wait();
  const s = load();
  // ON DELETE RESTRICT: no se borra un módulo que todavía tiene temas.
  if (s.temas.some((t) => t.moduloId === id)) {
    throw new Error("No se puede eliminar: el módulo todavía tiene temas.");
  }
  s.modulos = s.modulos.filter((m) => m.id !== id);
  save(s);
}

// ---------- Simulado: temas ----------

async function mockListTemas(moduloId: number): Promise<Tema[]> {
  await wait();
  return load()
    .temas.filter((t) => t.moduloId === moduloId)
    .sort((a, b) => a.orden - b.orden);
}

async function mockSaveTema(moduloId: number, input: ContenidoInput, id?: number): Promise<Tema> {
  await wait();
  validate(input);
  const data = clean(input);
  const s = load();

  if (s.temas.some((t) => t.moduloId === moduloId && t.orden === data.orden && t.id !== id)) {
    throw new Error("Ya existe un tema con ese orden en el módulo.");
  }

  let saved: Tema;
  if (id === undefined) {
    saved = { id: s.nextId++, moduloId, ...data, actualizadoEn: now() };
    s.temas.push(saved);
  } else {
    const index = s.temas.findIndex((t) => t.id === id);
    if (index < 0) throw new Error("El tema ya no existe.");
    saved = { ...s.temas[index], ...data, actualizadoEn: now() };
    s.temas[index] = saved;
  }
  save(s);
  return saved;
}

async function mockDeleteTema(id: number): Promise<void> {
  await wait();
  const s = load();
  s.temas = s.temas.filter((t) => t.id !== id);
  save(s);
}

// ---------- API real ----------
// PROVISIONAL: estos endpoints todavía no existen en el backend.
// Contrato propuesto (a acordar con Porfirio), respuestas { success, data }.

interface Wrapped<T> {
  success: boolean;
  data: T;
}

async function apiGet<T>(path: string, token: string | null): Promise<T> {
  return (await request<Wrapped<T>>(path, { token })).data;
}

async function apiSend<T>(
  path: string,
  method: "POST" | "PUT",
  body: unknown,
  token: string | null
): Promise<T> {
  return (await request<Wrapped<T>>(path, { method, body, token })).data;
}

// ---------- Funciones públicas (las que usarán las pantallas) ----------

export function listModulos(token: string | null): Promise<Modulo[]> {
  return USE_MOCK ? mockListModulos() : apiGet<Modulo[]>("/modulos", token);
}

export function createModulo(token: string | null, input: ContenidoInput): Promise<Modulo> {
  return USE_MOCK ? mockSaveModulo(input) : apiSend<Modulo>("/modulos", "POST", input, token);
}

export function updateModulo(token: string | null, id: number, input: ContenidoInput): Promise<Modulo> {
  return USE_MOCK ? mockSaveModulo(input, id) : apiSend<Modulo>(`/modulos/${id}`, "PUT", input, token);
}

export async function deleteModulo(token: string | null, id: number): Promise<void> {
  if (USE_MOCK) return mockDeleteModulo(id);
  await request<unknown>(`/modulos/${id}`, { method: "DELETE", token });
}

export function listTemas(token: string | null, moduloId: number): Promise<Tema[]> {
  return USE_MOCK ? mockListTemas(moduloId) : apiGet<Tema[]>(`/modulos/${moduloId}/temas`, token);
}

export function createTema(token: string | null, moduloId: number, input: ContenidoInput): Promise<Tema> {
  return USE_MOCK
    ? mockSaveTema(moduloId, input)
    : apiSend<Tema>(`/modulos/${moduloId}/temas`, "POST", input, token);
}

export function updateTema(token: string | null, moduloId: number, id: number, input: ContenidoInput): Promise<Tema> {
  return USE_MOCK
    ? mockSaveTema(moduloId, input, id)
    : apiSend<Tema>(`/temas/${id}`, "PUT", input, token);
}

export async function deleteTema(token: string | null, id: number): Promise<void> {
  if (USE_MOCK) return mockDeleteTema(id);
  await request<unknown>(`/temas/${id}`, { method: "DELETE", token });
}