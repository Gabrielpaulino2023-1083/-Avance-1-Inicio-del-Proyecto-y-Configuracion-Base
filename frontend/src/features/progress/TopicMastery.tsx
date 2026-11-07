import type { TopicProgress } from "../../services/progressService";

const LABELS: Record<TopicProgress["status"], string> = {
  strong: "Dominado",
  steady: "En progreso",
  reinforce: "Reforzar",
};

export default function TopicMastery({ topics }: { topics: TopicProgress[] }) {
  return (
    <section className="panel" aria-labelledby="topics-title">
      <div className="panel__head">
        <h2 id="topics-title" className="panel__title">
          Dominio por tema
        </h2>
      </div>

      <ul className="topics">
        {topics.map((t) => (
          <li key={t.id} className="topic">
            <div className="topic__row">
              <span className="topic__name">{t.name}</span>
              <span className={`topic__chip topic__chip--${t.status}`}>
                {LABELS[t.status]}
              </span>
            </div>
            <div
              className="topic__bar"
              role="progressbar"
              aria-valuenow={t.mastery}
              aria-valuemin={0}
              aria-valuemax={100}
              aria-label={t.name}
            >
              <span
                className={`topic__fill topic__fill--${t.status}`}
                style={{ width: `${t.mastery}%` }}
              />
            </div>
            <span className="topic__percent">{t.mastery}%</span>
          </li>
        ))}
      </ul>
    </section>
  );
}