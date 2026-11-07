// Punto único de comunicación con el backend.
// Todos los servicios usan request() para no repetir fetch, encabezados ni errores.

export const API_URL =
  import.meta.env.VITE_API_URL ?? "http://localhost:3000/api";

// Mientras se prueba sin backend se usan datos simulados.
// Para usar la API real: VITE_USE_MOCK=false en frontend/.env.local
export const USE_MOCK = import.meta.env.VITE_USE_MOCK !== "false";

export class ApiError extends Error {
  status: number;

  constructor(message: string, status: number) {
    super(message);
    this.name = "ApiError";
    this.status = status;
  }
}

// Formato de error del backend: { success:false, message, details?: [{campo, mensaje}] }
interface ErrorBody {
  message?: string;
  details?: { campo: string; mensaje: string }[];
}

interface RequestOptions {
  method?: "GET" | "POST";
  body?: unknown;
  token?: string | null;
}

export async function request<T>(
  path: string,
  { method = "GET", body, token }: RequestOptions = {}
): Promise<T> {
  let response: Response;

  try {
    response = await fetch(`${API_URL}${path}`, {
      method,
      headers: {
        "Content-Type": "application/json",
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
  } catch {
    throw new ApiError(
      "No se pudo conectar con el servidor. Verifica que el backend esté encendido.",
      0
    );
  }

  const data = await response.json().catch(() => null);

  if (!response.ok) {
    const error = (data ?? {}) as ErrorBody;
    const detail = error.details?.map((d) => d.mensaje).join(" ");
    throw new ApiError(
      detail || error.message || "Ocurrió un error inesperado.",
      response.status
    );
  }

  return data as T;
}