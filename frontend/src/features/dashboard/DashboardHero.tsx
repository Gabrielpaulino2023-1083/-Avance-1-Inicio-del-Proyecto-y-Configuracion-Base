import { Link } from "react-router-dom";
import type { DashboardSummary } from "../../types";
import ProgressRing from "./ProgressRing";

interface Props {
  name: string;
  summary: DashboardSummary;
}

export default function DashboardHero({ name, summary }: Props) {
  const change = summary.weeklyChange;

  return (
    <section className="hero" aria-labelledby="hero-title">
      <svg
        className="hero__net"
        viewBox="0 0 800 400"
        preserveAspectRatio="xMidYMid slice"
        aria-hidden="true"
      >
        <g stroke="#ffffff" strokeWidth="1" fill="none">
          <path d="M60 320 L220 220 L380 290 L540 150 L720 230" />
          <path d="M220 220 L300 90 L540 150" />
          <path d="M380 290 L470 370 L720 230" />
        </g>
        <g fill="#ffffff">
          <circle cx="60" cy="320" r="4" />
          <circle cx="220" cy="220" r="5" />
          <circle cx="300" cy="90" r="4" />
          <circle cx="380" cy="290" r="5" />
          <circle cx="470" cy="370" r="3" />
          <circle cx="540" cy="150" r="5" />
          <circle cx="720" cy="230" r="4" />
        </g>
      </svg>
      <span className="hero__orb hero__orb--a" aria-hidden="true" />
      <span className="hero__orb hero__orb--b" aria-hidden="true" />

      <div className="hero__content">
        <p className="hero__greeting">Bienvenido, {name}</p>
        <h1 id="hero-title">Tu aprendizaje evoluciona contigo.</h1>
        <p className="hero__lead">
          La plataforma analiza tu progreso, identifica fortalezas y adapta el
          contenido para ayudarte a alcanzar tus objetivos académicos de forma
          más eficiente.
        </p>
        <div className="hero__actions">
          <Link to="/contenido" className="btn btn--primary">
            Continuar estudio
          </Link>
          <Link to="/progreso" className="btn btn--ghost">
            Ver progreso
          </Link>
        </div>
      </div>

      <div className="hero__panel">
        <ProgressRing percent={summary.progressPercent} />
        <ul className="hero__facts">
          <li className="fact">
            <strong>{summary.modulesCompleted}</strong>
            <span>módulos finalizados</span>
          </li>
          <li className="fact">
            <strong>{summary.modulesPending}</strong>
            <span>pendientes</span>
          </li>
          <li className="fact fact--up">
            <strong>
              {change > 0 ? "+" : ""}
              {change}%
            </strong>
            <span>respecto a la semana anterior</span>
          </li>
        </ul>
        <p className="hero__note">Datos de ejemplo mientras se conecta el backend</p>
      </div>
    </section>
  );
}