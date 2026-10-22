import { useAuth } from "../../context/authContext";
import { useDashboardSummary } from "../../features/dashboard/useDashboardSummary";
import DashboardHero from "../../features/dashboard/DashboardHero";
import "../../features/dashboard/dashboard.css";
import StatCards from "../../features/dashboard/StatCards";
import RecommendationCard from "../../features/dashboard/RecommendationCard";
import ActivityTimeline from "../../features/dashboard/ActivityTimeline";

export default function DashboardScreen() {
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
      <RecommendationCard
        recommendation={summary.recommendation}
        evidence={summary.evidence}
      />
      <ActivityTimeline items={summary.recentActivity} />
    </div>
  );
}