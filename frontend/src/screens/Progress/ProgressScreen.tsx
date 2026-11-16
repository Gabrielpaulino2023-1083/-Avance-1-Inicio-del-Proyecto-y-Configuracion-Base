import { useEffect, useState } from "react";
import { useAuth } from "../../context/authContext";
import { useDashboardSummary } from "../../features/dashboard/useDashboardSummary";
import RecommendationCard from "../../features/dashboard/RecommendationCard";
import WeeklyHoursChart from "../../features/progress/WeeklyHoursChart";
import TopicMastery from "../../features/progress/TopicMastery";
import { ApiError, USE_MOCK } from "../../services/http";
import {
  getProgressDetail,
  type ProgressDetail,
} from "../../services/progressService";
import "../../features/dashboard/dashboard.css";
import "../../features/progress/progress.css";

export default function ProgressScreen() {
  const { token, logout } = useAuth();
  const { summary, error } = useDashboardSummary();
  const [detail, setDetail] = useState<ProgressDetail | null>(null);
  const [detailError, setDetailError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    getProgressDetail(token)
      .then((data) => {
        if (active) setDetail(data);
      })
      .catch((err: unknown) => {
        if (!active) return;
        if (err instanceof ApiError && err.status === 401) {
          logout();
          return;
        }
        setDetailError(
          err instanceof Error
            ? err.message
            : "No se pudo cargar el detalle de tu progreso."
        );
      });
    return () => {
      active = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token]);

  const failure = error ?? detailError;
  if (failure) {
    return (
      <p className="dash-state dash-state--error" role="alert">
        {failure}
      </p>
    );
  }

  if (!summary || !detail) {
    return (
      <div className="dash-state" aria-busy="true">
        Analizando tu progreso...
      </div>
    );
  }

  return (
    <div className="dash">
      <header className="page-head">
        <h1>Tu progreso</h1>
        <p>
          {USE_MOCK
            ? "Así evoluciona tu estudio y qué temas conviene reforzar. Datos de ejemplo (modo simulado)."
            : "Así evoluciona tu estudio y qué temas conviene reforzar. Las horas salen del tiempo de tus intentos y el dominio, del promedio de tus notas por tema."}
        </p>
      </header>

      <div className="progress-row">
        <WeeklyHoursChart data={detail.weeklyHours} />
        <TopicMastery topics={detail.topics} />
      </div>

      {summary.recommendation && summary.evidence ? (
        <RecommendationCard
          recommendation={summary.recommendation}
          evidence={summary.evidence}
          sample={USE_MOCK}
        />
      ) : (
        <p className="dash-state">
          Aún no hay recomendación: completa una evaluación para que el motor
          analice tu desempeño.
        </p>
      )}
    </div>
  );
}