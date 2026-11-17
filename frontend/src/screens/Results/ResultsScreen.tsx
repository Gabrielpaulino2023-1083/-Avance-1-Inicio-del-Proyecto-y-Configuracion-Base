import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../../context/authContext";
import ResultStats from "../../features/results/ResultStats";
import ScoreTrend from "../../features/results/ScoreTrend";
import ResultsTable from "../../features/results/ResultsTable";
import { ApiError, USE_MOCK } from "../../services/http";
import {
  PASSING_SCORE,
  getEvaluations,
  type Evaluation,
} from "../../services/resultsService";
import "../../features/dashboard/dashboard.css";
import "../../features/progress/progress.css";
import "../../features/results/results.css";

export default function ResultsScreen() {
  const { token, logout } = useAuth();
  const [evaluations, setEvaluations] = useState<Evaluation[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    getEvaluations(token)
      .then((data) => {
        if (active) setEvaluations(data);
      })
      .catch((err: unknown) => {
        if (!active) return;
        if (err instanceof ApiError && err.status === 401) {
          logout();
          return;
        }
        setError(
          err instanceof Error
            ? err.message
            : "No se pudieron cargar tus resultados."
        );
      });
    return () => {
      active = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token]);

  const header = (
    <header className="page-head">
      <h1>Tus resultados</h1>
      <p>
        {USE_MOCK
          ? "Revisa cómo te ha ido en cada evaluación. Datos de ejemplo (modo simulado)."
          : "Notas de tus actividades calificadas, calculadas por el servidor. Los errores por evaluación no se guardan, por eso aparece un guion."}
      </p>
    </header>
  );

  if (error) {
    return (
      <p className="dash-state dash-state--error" role="alert">
        {error}
      </p>
    );
  }

  if (!evaluations) {
    return (
      <div className="dash-state" aria-busy="true">
        Cargando tus resultados...
      </div>
    );
  }

  if (evaluations.length === 0) {
    return (
      <div className="dash">
        {header}
        <p className="dash-state">
          Aún no tienes evaluaciones calificadas. Completa una actividad en{" "}
          <Link to="/contenido">Contenido</Link> y aquí verás tu nota.
        </p>
      </div>
    );
  }

  const lowest = evaluations.reduce((min, e) => (e.score < min.score ? e : min));

  return (
    <div className="dash">
      {header}

      <ResultStats evaluations={evaluations} />

      <div className="results-row">
        <ScoreTrend evaluations={evaluations} />

        {lowest.score < PASSING_SCORE && (
          <aside className="insight insight--card" role="note">
            <span className="insight__eyebrow">Qué reforzar</span>
            <p className="insight__topic">{lowest.title}</p>
            <p>
              Quedó en {lowest.score}%, por debajo del mínimo de{" "}
              {PASSING_SCORE}%. Practicar un poco más te ayudará a subir esa
              nota.
            </p>
            <Link to="/contenido" className="insight__link">
              Ir al ejercicio
            </Link>
          </aside>
        )}
      </div>

      <ResultsTable evaluations={evaluations} />
    </div>
  );
}