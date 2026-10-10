import type { LoginRequest, LoginResponse } from "../types";

const API_URL = import.meta.env.VITE_API_URL ?? "http://localhost:3000/api";

// Mientras el backend no esté listo, se usan datos simulados.
// Para usar la API real, crear un archivo .env.local con: VITE_USE_MOCK=false
const USE_MOCK = import.meta.env.VITE_USE_MOCK !== "false";

// Usuario de prueba, basado en el seed de la base de datos (estudiante@example.com).
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

async function mockLogin(data: LoginRequest): Promise<LoginResponse> {
  await wait(700); // simula el tiempo de respuesta de una red real

  const emailOk = data.email.trim().toLowerCase() === MOCK_EMAIL;
  if (!emailOk || data.password !== MOCK_PASSWORD) {
    throw new Error("Correo o contraseña incorrectos.");
  }
  return MOCK_RESPONSE;
}

async function apiLogin(data: LoginRequest): Promise<LoginResponse> {
  // PROVISIONAL: la ruta y el formato los debe confirmar el compañero de Backend.
  const response = await fetch(`${API_URL}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  });

  if (!response.ok) {
    throw new Error(
      response.status === 401
        ? "Correo o contraseña incorrectos."
        : "No se pudo iniciar sesión. Intenta de nuevo."
    );
  }
  return response.json();
}

export function login(data: LoginRequest): Promise<LoginResponse> {
  return USE_MOCK ? mockLogin(data) : apiLogin(data);
}