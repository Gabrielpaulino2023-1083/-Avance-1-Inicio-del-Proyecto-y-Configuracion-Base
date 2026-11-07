import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../../context/authContext";
import { getDashboardSummary } from "../../services/dashboardService";
import { ApiError } from "../../services/http";
import type { DashboardSummary } from "../../types";

// Carga el resumen del estudiante y maneja el token vencido (dura 2 horas).
// Lo usan el Dashboard y el Progreso.
export function useDashboardSummary() {
  const { user, token, logout } = useAuth();
  const navigate = useNavigate();
  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [sessionExpired, setSessionExpired] = useState(false);

  const userId = user?.id ?? null;

  useEffect(() => {
    let active = true;
    getDashboardSummary(token, userId)
      .then((data) => {
        if (active) setSummary(data);
      })
      .catch((err: unknown) => {
        if (!active) return;
        if (err instanceof ApiError && err.status === 401) {
          setSessionExpired(true);
          return;
        }
        setError(
          err instanceof Error
            ? err.message
            : "No se pudo cargar tu información. Intenta de nuevo."
        );
      });
    return () => {
      active = false;
    };
  }, [token, userId]);

  useEffect(() => {
    if (sessionExpired) {
      logout();
      navigate("/login");
    }
  }, [sessionExpired, logout, navigate]);

  return { summary, error };
}