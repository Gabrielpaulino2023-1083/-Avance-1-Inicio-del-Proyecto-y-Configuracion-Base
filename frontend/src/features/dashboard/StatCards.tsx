import type { ReactNode } from "react";
import type { DashboardSummary } from "../../types";
import { useCountUp } from "./useCountUp";

interface StatDef {
  key: string;
  label: string;
  value: number;
  suffix: string;
  delta: number;
  deltaText: string;
  positiveIsGood: boolean;
  icon: ReactNode;
}

function StatCard({ stat }: { stat: StatDef }) {
  const shown = useCountUp(stat.value, 800);
  const isGood = stat.positiveIsGood ? stat.delta >= 0 : stat.delta <= 0;
  const sign = stat.delta > 0 ? "+" : stat.delta < 0 ? "−" : "";

  return (
    <article className="stat">
      <span className="stat__icon" aria-hidden="true">
        <svg viewBox="0 0 24 24">{stat.icon}</svg>
      </span>
      <div>
        <p className="stat__value">
          {Math.round(shown)}
          {stat.suffix}
        </p>
        <p className="stat__label">{stat.label}</p>
      </div>
      <span
        className={`stat__delta ${isGood ? "stat__delta--good" : "stat__delta--bad"}`}
      >
        {sign}
        {Math.abs(stat.delta)} {stat.deltaText}
      </span>
    </article>
  );
}

export default function StatCards({ summary }: { summary: DashboardSummary }) {
  const { trends } = summary;

  const stats: StatDef[] = [
    {
      key: "courses",
      label: "Cursos activos",
      value: summary.activeCourses,
      suffix: "",
      delta: trends.activeCourses,
      deltaText: "este mes",
      positiveIsGood: true,
      icon: (
        <>
          <path d="M2 4h7a3 3 0 0 1 3 3v13a2 2 0 0 0-2-2H2z" />
          <path d="M22 4h-7a3 3 0 0 0-3 3v13a2 2 0 0 1 2-2h8z" />
        </>
      ),
    },
    {
      key: "pending",
      label: "Actividades pendientes",
      value: summary.pendingActivities,
      suffix: "",
      delta: trends.pendingActivities,
      deltaText: "vs. semana pasada",
      positiveIsGood: false,
      icon: (
        <>
          <path d="M9 6h12M9 12h12M9 18h12" />
          <path d="M3 6l1.5 1.5L7 5M3 12l1.5 1.5L7 11M3 18l1.5 1.5L7 17" />
        </>
      ),
    },
    {
      key: "score",
      label: "Nota promedio",
      value: summary.averageScore,
      suffix: "%",
      delta: trends.averageScore,
      deltaText: "puntos",
      positiveIsGood: true,
      icon: (
        <>
          <circle cx="12" cy="12" r="9" />
          <circle cx="12" cy="12" r="5" />
          <circle cx="12" cy="12" r="1" />
        </>
      ),
    },
    {
      key: "hours",
      label: "Horas de estudio",
      value: summary.studyHours,
      suffix: " h",
      delta: trends.studyHours,
      deltaText: "h esta semana",
      positiveIsGood: true,
      icon: (
        <>
          <circle cx="12" cy="12" r="9" />
          <path d="M12 7v5l3 2" />
        </>
      ),
    },
  ];

  return (
    <section className="stats" aria-label="Resumen rápido">
      {stats.map((stat) => (
        <StatCard key={stat.key} stat={stat} />
      ))}
    </section>
  );
}