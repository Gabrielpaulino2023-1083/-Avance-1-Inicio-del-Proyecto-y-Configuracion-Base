import { useEffect, useState } from "react";
import { useDashboardSummary } from "../../features/dashboard/useDashboardSummary";
import RecommendationCard from "../../features/dashboard/RecommendationCard";
import WeeklyHoursChart from "../../features/progress/WeeklyHoursChart";
import TopicMastery from "../../features/progress/TopicMastery";
import {
  getProgressDetail,
  type ProgressDetail,
} from "../../services/progressService";
import "../../features/dashboard/dashboard.css";
import "../../features/progress/progress.css";

export default function ProgressScreen() {
  const { summary, error } = useDashboardSummary();
  const [detail, setDetail] = useState<ProgressDetail | null>(null);

  useEffect(() => {
    let active = true;
    getProgressDetail().then((data) => {
      if (active) setDetail(data);
    });
    return () => {
      active = false;
    };
  }, []);

  if (error) {
    return (
      <p className="dash-state dash-state--error" role="alert">
        {error}
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
          Así evoluciona tu estudio y qué temas conviene reforzar. Datos de
          ejemplo mientras se conecta el backend.
        </p>
      </header>

      <div className="progress-row">
        <WeeklyHoursChart data={detail.weeklyHours} />
        <TopicMastery topics={detail.topics} />
      </div>

      <div className="dash__row">
        <RecommendationCard recommendation={summary.recommendation} />
      </div>
    </div>
  );
}