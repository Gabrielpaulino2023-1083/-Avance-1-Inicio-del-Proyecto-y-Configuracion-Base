import { useAuth } from "../../context/authContext";
import { Link } from "react-router-dom";
import { USE_MOCK } from "../../services/http";
import { useDashboardSummary } from "../../features/dashboard/useDashboardSummary";
import DashboardHero from "../../features/dashboard/DashboardHero";
import "../../features/dashboard/dashboard.css";
import StatCards from "../../features/dashboard/StatCards";
import RecommendationCard from "../../features/dashboard/RecommendationCard";
import ActivityTimeline from "../../features/dashboard/ActivityTimeline";
import StaffDashboard from "../../features/dashboard/StaffDashboard";

// Panel del estudiante: progreso, notas, recomendación del motor y actividad.
function StudentDashboard() {
  const { user } = useAuth();
  const { summary, error } = useDashboardSummary();

  if (error) {
    return (
      <p className="dash-state dash-state--error" role="alert">
        {error}
      </p>
    );
  }

  if (!summary) {
    return (
      <div className="dash-state" aria-busy="true">
        Preparando tu panel...
      </div>
    );
  }

  return (
    <div className="dash">
      <DashboardHero name={user?.nombre ?? "estudiante"} summary={summary} />
      <StatCards summary={summary} />
      <div className="dash__row">
                       {summary.recommendation && summary.evidence ? (
          <RecommendationCard
            recommendation={summary.recommendation}
            evidence={summary.evidence}
            sample={USE_MOCK}
          />
        ) : (
          <section className="ai-card ai-card--steady" aria-labelledby="ai-title">
            <div className="ai-card__main">
              <span className="ai-card__badge">Análisis del motor adaptativo</span>
              <h2 id="ai-title" className="ai-card__title">
                Aún no hay recomendación
              </h2>
              <p className="ai-card__text">
                Completa una evaluación para que el motor analice tu desempeño
                y te recomiende cómo seguir.
              </p>
              <div className="ai-card__foot">
                <Link to="/contenido" className="btn btn--primary">
                  Ir a las actividades
                </Link>
              </div>
            </div>
          </section>
        )}
        <ActivityTimeline items={summary.recentActivity} />
      </div>
    </div>
  );
}

// Cada rol ve su propio panel de inicio.
export default function DashboardScreen() {
  const { user } = useAuth();
  if (user && user.rol !== "ESTUDIANTE") return <StaffDashboard />;
  return <StudentDashboard />;
}