import type { LoginRequest, LoginResponse, User } from "../types";
import { request, USE_MOCK } from "./http";

export interface RegisterRequest {
  nombre: string;
  apellido: string;
  email: string;
  password: string;
}

// Usuario de prueba para el modo simulado.
// La contraseña es solo del simulador: no es una credencial real.
const MOCK_EMAIL = "estudiante@example.com";
const MOCK_PASSWORD = "estudiante123";

const MOCK_RESPONSE: LoginResponse = {
  token: "token-simulado",
  user: {
    id: 1,
    nombre: "Estudiante",
    apellido: "",
    email: MOCK_EMAIL,
    rol: "ESTUDIANTE",
  },
};

function wait(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ---------- Login ----------

async function mockLogin(data: LoginRequest): Promise<LoginResponse> {
  await wait(700); // simula el tiempo de respuesta de una red real

  const emailOk = data.email.trim().toLowerCase() === MOCK_EMAIL;
  if (!emailOk || data.password !== MOCK_PASSWORD) {
    throw new Error("Correo o contraseña incorrectos.");
  }
  return MOCK_RESPONSE;
}

// Respuesta real de POST /api/auth/login
interface LoginApiResponse {
  success: boolean;
  token: string;
  user: User;
}

async function apiLogin(data: LoginRequest): Promise<LoginResponse> {
  const result = await request<LoginApiResponse>("/auth/login", {
    method: "POST",
    body: data,
  });
  return { token: result.token, user: result.user };
}

export function login(data: LoginRequest): Promise<LoginResponse> {
  return USE_MOCK ? mockLogin(data) : apiLogin(data);
}

// ---------- Registro ----------

async function mockRegister(data: RegisterRequest): Promise<void> {
  await wait(700);
  // Imita el error 409 del backend cuando el correo ya existe.
  if (data.email.trim().toLowerCase() === MOCK_EMAIL) {
    throw new Error("Ya existe un usuario con ese email");
  }
}

async function apiRegister(data: RegisterRequest): Promise<void> {
  // POST /api/auth/register responde 201 con { success, user }
  await request<unknown>("/auth/register", { method: "POST", body: data });
}

export function register(data: RegisterRequest): Promise<void> {
  return USE_MOCK ? mockRegister(data) : apiRegister(data);
}