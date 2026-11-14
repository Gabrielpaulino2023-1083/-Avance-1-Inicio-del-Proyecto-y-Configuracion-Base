import { useAuth } from "../../context/authContext";
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
        <RecommendationCard
          recommendation={summary.recommendation}
          evidence={summary.evidence}
        />
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