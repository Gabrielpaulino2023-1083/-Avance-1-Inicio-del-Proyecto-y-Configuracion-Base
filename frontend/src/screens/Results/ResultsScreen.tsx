import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import ResultStats from "../../features/results/ResultStats";
import ScoreTrend from "../../features/results/ScoreTrend";
import ResultsTable from "../../features/results/ResultsTable";
import {
  PASSING_SCORE,
  getEvaluations,
  type Evaluation,
} from "../../services/resultsService";
import "../../features/dashboard/dashboard.css";
import "../../features/progress/progress.css";
import "../../features/results/results.css";

export default function ResultsScreen() {
  const [evaluations, setEvaluations] = useState<Evaluation[] | null>(null);

  useEffect(() => {
    let active = true;
    getEvaluations().then((data) => {
      if (active) setEvaluations(data);
    });
    return () => {
      active = false;
    };
  }, []);

  if (!evaluations) {
    return (
      <div className="dash-state" aria-busy="true">
        Cargando tus resultados...
      </div>
    );
  }

  const lowest = evaluations.reduce((min, e) => (e.score < min.score ? e : min));

  return (
    <div className="dash">
      <header className="page-head">
        <h1>Tus resultados</h1>
        <p>
          Revisa cómo te ha ido en cada evaluación. Datos de ejemplo mientras
          se conecta el backend.
        </p>
      </header>

      <ResultStats evaluations={evaluations} />

      {lowest.score < PASSING_SCORE && (
        <div className="insight" role="note">
          <p>
            <strong>{lowest.title}</strong> quedó en {lowest.score}%, por debajo
            del mínimo de {PASSING_SCORE}%. Practicar un poco más te ayudará a
            subir esa nota.
          </p>
          <Link to="/contenido" className="insight__link">
            Ir al ejercicio
          </Link>
        </div>
      )}

      <ScoreTrend evaluations={evaluations} />
      <ResultsTable evaluations={evaluations} />
    </div>
  );
}