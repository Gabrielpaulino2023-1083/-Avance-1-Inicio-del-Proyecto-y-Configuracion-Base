import { useEffect, useState } from "react";
import { useAuth } from "../../context/authContext";
import { getDashboardSummary } from "../../services/dashboardService";
import type { DashboardSummary } from "../../types";
import DashboardHero from "../../features/dashboard/DashboardHero";
import "../../features/dashboard/dashboard.css";
import StatCards from "../../features/dashboard/StatCards";
import RecommendationCard from "../../features/dashboard/RecommendationCard";

export default function DashboardScreen() {
  const { user, token } = useAuth();
  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    getDashboardSummary(token)
      .then((data) => {
        if (active) setSummary(data);
      })
      .catch(() => {
        if (active) setError("No se pudo cargar tu información. Intenta de nuevo.");
      });
    return () => {
      active = false;
    };
  }, [token]);

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
        <RecommendationCard recommendation={summary.recommendation} />
      </div>
    </div>
  );
}