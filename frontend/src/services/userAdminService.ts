import type { RolUsuario, UsuarioAdmin } from "../types/userAdmin";
import { request, USE_MOCK } from "./http";

// La pantalla solo se muestra con datos simulados, o con la API real cuando el
// backend tenga las rutas y se active VITE_ENABLE_USER_ADMIN=true.
export const USER_ADMIN_ENABLED =
  USE_MOCK || import.meta.env.VITE_ENABLE_USER_ADMIN === "true";

// ---------- Simulación (localStorage) ----------

const STORAGE_KEY = "adaptativo.usuarios";
const wait = (ms = 350) => new Promise((resolve) => setTimeout(resolve, ms));
const now = () => new Date().toISOString();

function seed(): UsuarioAdmin[] {
  const t = now();
  return [
    { id: 1, nombre: "Estudiante", apellido: "", email: "estudiante@example.com", rol: "ESTUDIANTE", activo: true, creadoEn: t },
    { id: 2, nombre: "Docente", apellido: "", email: "docente@example.com", rol: "DOCENTE", activo: true, creadoEn: t },
    { id: 3, nombre: "Administrador", apellido: "", email: "administrador@example.com", rol: "ADMINISTRADOR", activo: true, creadoEn: t },
    { id: 4, nombre: "Ana", apellido: "Pérez", email: "ana.perez@example.com", rol: "ESTUDIANTE", activo: true, creadoEn: t },
    { id: 5, nombre: "Luis", apellido: "Gómez", email: "luis.gomez@example.com", rol: "ESTUDIANTE", activo: false, creadoEn: t },
    { id: 6, nombre: "Marta", apellido: "Díaz", email: "marta.diaz@example.com", rol: "DOCENTE", activo: true, creadoEn: t },
  ];
}

function load(): UsuarioAdmin[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) return JSON.parse(raw) as UsuarioAdmin[];
  } catch {
    /* si el almacenamiento falla, se usan los datos de ejemplo */
  }
  return seed();
}

function save(users: UsuarioAdmin[]) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(users));
  } catch {
    /* sin almacenamiento: los cambios duran mientras la página esté abierta */
  }
}

const activeAdmins = (users: UsuarioAdmin[]) =>
  users.filter((u) => u.rol === "ADMINISTRADOR" && u.activo).length;

async function mockList(): Promise<UsuarioAdmin[]> {
  await wait();
  return load();
}

// Mismas reglas que debe validar el backend: nadie cambia su propio rol ni se
// desactiva, y siempre queda al menos un administrador activo.
async function mockChangeRol(
  id: number,
  rol: RolUsuario,
  actorId: number
): Promise<UsuarioAdmin> {
  await wait();
  const users = load();
  const index = users.findIndex((u) => u.id === id);
  if (index < 0) throw new Error("El usuario no existe.");
  const target = users[index];
  if (target.id === actorId) {
    throw new Error("No puedes cambiar tu propio rol.");
  }
  if (target.rol === "ADMINISTRADOR" && rol !== "ADMINISTRADOR" && target.activo && activeAdmins(users) <= 1) {
    throw new Error("Debe quedar al menos un administrador activo.");
  }
  users[index] = { ...target, rol };
  save(users);
  return users[index];
}

async function mockChangeActivo(
  id: number,
  activo: boolean,
  actorId: number
): Promise<UsuarioAdmin> {
  await wait();
  const users = load();
  const index = users.findIndex((u) => u.id === id);
  if (index < 0) throw new Error("El usuario no existe.");
  const target = users[index];
  if (!activo && target.id === actorId) {
    throw new Error("No puedes desactivar tu propia cuenta.");
  }
  if (!activo && target.rol === "ADMINISTRADOR" && target.activo && activeAdmins(users) <= 1) {
    throw new Error("Debe quedar al menos un administrador activo.");
  }
  users[index] = { ...target, activo };
  save(users);
  return users[index];
}

// ---------- API real (contrato propuesto, pendiente en el backend) ----------

interface Wrapped<T> {
  success: boolean;
  data: T;
}

// ---------- Funciones públicas ----------

export async function listUsuarios(token: string | null): Promise<UsuarioAdmin[]> {
  if (USE_MOCK) return mockList();
  const res = await request<Wrapped<UsuarioAdmin[]>>("/usuarios", { token });
  return res.data;
}

// actorId solo lo usa la simulación; con la API real, el backend toma el
// administrador del token.
export async function changeUsuarioRol(
  token: string | null,
  id: number,
  rol: RolUsuario,
  actorId: number
): Promise<UsuarioAdmin> {
  if (USE_MOCK) return mockChangeRol(id, rol, actorId);
  const res = await request<Wrapped<UsuarioAdmin>>(`/usuarios/${id}/rol`, {
    method: "PATCH",
    body: { rol },
    token,
  });
  return res.data;
}

export async function changeUsuarioActivo(
  token: string | null,
  id: number,
  activo: boolean,
  actorId: number
): Promise<UsuarioAdmin> {
  if (USE_MOCK) return mockChangeActivo(id, activo, actorId);
  const res = await request<Wrapped<UsuarioAdmin>>(`/usuarios/${id}/estado`, {
    method: "PATCH",
    body: { activo },
    token,
  });
  return res.data;
}