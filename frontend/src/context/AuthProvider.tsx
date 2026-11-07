import { useState, type ReactNode } from "react";
import { AuthContext } from "./authContext";
import { login as loginRequest } from "../services/authService";
import type { LoginRequest, User } from "../types";

const STORAGE_KEY = "adaptativo.session";

interface Session {
  token: string;
  user: User;
}

function readSession(): Session | null {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as Session) : null;
  } catch {
    return null; // sin almacenamiento disponible: se empieza sin sesión
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(readSession);

  async function login(data: LoginRequest) {
    const { token, user } = await loginRequest(data);
    const next = { token, user };
    setSession(next);
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
    } catch {
      // si no se puede guardar, la sesión dura mientras la pestaña esté abierta
    }
  }

  function logout() {
    setSession(null);
    try {
      localStorage.removeItem(STORAGE_KEY);
    } catch {
      // nada que limpiar
    }
  }

  return (
    <AuthContext.Provider
      value={{
        user: session?.user ?? null,
        token: session?.token ?? null,
        isAuthenticated: session !== null,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}