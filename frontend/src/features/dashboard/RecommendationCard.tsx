import { Link } from "react-router-dom";
import type { Recommendation, RecommendationEvidence } from "../../types";
import "./ai-card.css";

const VIEW: Record<
  Recommendation["action"],
  { tone: string; priority: string; headline: (topic: string) => string }
> = {
  reinforce_topic: {
    tone: "high",
    priority: "Prioridad alta",
    headline: (topic) => `Detectamos dificultades en ${topic}`,
  },
  increase_difficulty: {
    tone: "up",
    priority: "Buen momento para avanzar",
    headline: (topic) => `Dominas ${topic}: es hora de subir el nivel`,
  },
  maintain_difficulty: {
    tone: "steady",
    priority: "Vas por buen camino",
    headline: (topic) => `Buen ritmo en ${topic}`,
  },
};

const DIFFICULTY_LABEL: Record<Recommendation["difficulty"], string> = {
  reduced: "Dificultad reducida",
  increased: "Dificultad aumentada",
  current: "Dificultad actual",
};

interface Props {
  recommendation: Recommendation;
  evidence: RecommendationEvidence;
}

export default function RecommendationCard({ recommendation, evidence }: Props) {
  const view = VIEW[recommendation.action];
  const mastery = Math.round(evidence.mastery);

  return (
    <section className={`ai-card ai-card--${view.tone}`} aria-labelledby="ai-title">
      <div className="ai-card__main">
        <span className="ai-card__badge">
          <svg viewBox="0 0 24 24" aria-hidden="true">
            <path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z" />
            <path d="M19 16l.7 2 2 .7-2 .7-.7 2-.7-2-2-.7 2-.7z" />
          </svg>
          Análisis del motor adaptativo
        </span>

        <h2 id="ai-title" className="ai-card__title">
          {view.headline(recommendation.topic)}
        </h2>
        <p className="ai-card__text">{recommendation.recommendation}</p>

        <div className="ai-card__foot">
          <Link to="/contenido" className="btn btn--primary">
            Ir al ejercicio
          </Link>
          <span className="ai-card__chip">
            {DIFFICULTY_LABEL[recommendation.difficulty]}
          </span>
          <span className="ai-card__priority">{view.priority}</span>
        </div>
      </div>

      <dl className="ai-card__evidence" aria-label="Datos que explican la recomendación">
        <div className="ai-card__metric ai-card__metric--main">
          <dt>Dominio del tema</dt>
          <dd>
            <span className="ai-card__num">{mastery}%</span>
            <span className="ai-card__meter" aria-hidden="true">
              <span style={{ width: `${mastery}%` }} />
            </span>
          </dd>
        </div>
        <div className="ai-card__metric">
          <dt>Errores acumulados</dt>
          <dd>
            <span className="ai-card__num">{evidence.errors}</span>
          </dd>
        </div>
        <div className="ai-card__metric">
          <dt>Intentos promedio</dt>
          <dd>
            <span className="ai-card__num">{evidence.attempts.toFixed(1)}</span>
          </dd>
        </div>
      </dl>
    </section>
  );
}