import { Link } from "react-router-dom";
import type { Recommendation } from "../../types";

const ACTION_VIEW: Record<
  Recommendation["action"],
  { tone: string; priority: string; verb: string }
> = {
  reinforce_topic: {
    tone: "high",
    priority: "Prioridad alta",
    verb: "Reforzar",
  },
  increase_difficulty: {
    tone: "up",
    priority: "Buen momento para avanzar",
    verb: "Subir el nivel en",
  },
  maintain_difficulty: {
    tone: "steady",
    priority: "Vas por buen camino",
    verb: "Continuar con",
  },
};

const DIFFICULTY_LABEL: Record<Recommendation["difficulty"], string> = {
  reduced: "Dificultad reducida",
  increased: "Dificultad aumentada",
  current: "Dificultad actual",
};

export default function RecommendationCard({
  recommendation,
}: {
  recommendation: Recommendation;
}) {
  const view = ACTION_VIEW[recommendation.action];

  return (
    <section className={`reco reco--${view.tone}`} aria-labelledby="reco-title">
      <div className="reco__head">
        <span className="reco__icon" aria-hidden="true">
          <svg viewBox="0 0 24 24">
            <path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z" />
            <path d="M19 16l.7 2 2 .7-2 .7-.7 2-.7-2-2-.7 2-.7z" />
          </svg>
        </span>
        <h2 id="reco-title" className="reco__title">
          Recomendación para ti
        </h2>
        <span className="reco__priority">{view.priority}</span>
      </div>

      <p className="reco__topic">
        {view.verb} {recommendation.topic}
      </p>
      <p className="reco__text">{recommendation.recommendation}</p>

      <div className="reco__why">
        <strong>Por qué te lo recomendamos</strong>
        <span>{recommendation.reason}</span>
      </div>

      <div className="reco__foot">
        <Link to="/contenido" className="btn btn--primary">
          Ir al ejercicio
        </Link>
        <span className="reco__chip">
          {DIFFICULTY_LABEL[recommendation.difficulty]}
        </span>
      </div>
    </section>
  );
}