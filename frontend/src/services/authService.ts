import type { LoginRequest, LoginResponse, User } from "../types";
import { request, USE_MOCK } from "./http";

export interface RegisterRequest {
  nombre: string;
  apellido: string;
  email: string;
  password: string;
}

// Usuarios de prueba para el modo simulado.
// Las contraseñas son solo del simulador: no son credenciales reales.
const MOCK_EMAIL = "estudiante@example.com";

interface MockAccount {
  password: string;
  response: LoginResponse;
}

function mockAccount(password: string, user: User, token: string): MockAccount {
  return { password, response: { token, user } };
}

const MOCK_ACCOUNTS: Record<string, MockAccount> = {
  [MOCK_EMAIL]: mockAccount(
    "estudiante123",
    { id: 1, nombre: "Estudiante", apellido: "", email: MOCK_EMAIL, rol: "ESTUDIANTE" },
    "token-simulado"
  ),
  "docente@example.com": mockAccount(
    "docente123",
    { id: 2, nombre: "Docente", apellido: "", email: "docente@example.com", rol: "DOCENTE" },
    "token-simulado-docente"
  ),
};

function wait(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ---------- Login ----------

async function mockLogin(data: LoginRequest): Promise<LoginResponse> {
  await wait(700); // simula el tiempo de respuesta de una red real

  const account = MOCK_ACCOUNTS[data.email.trim().toLowerCase()];
  if (!account || data.password !== account.password) {
    throw new Error("Correo o contraseña incorrectos.");
  }
  return account.response;
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
  if (MOCK_ACCOUNTS[data.email.trim().toLowerCase()]) {
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