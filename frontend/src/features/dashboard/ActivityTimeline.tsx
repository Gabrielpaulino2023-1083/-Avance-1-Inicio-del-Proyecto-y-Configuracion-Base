import type { ReactNode } from "react";
import type { ActivityItem } from "../../types";

// Un icono por tipo de actividad (mismo estilo de línea que el resto del panel).
const ICONS: Record<ActivityItem["kind"], ReactNode> = {
  lesson: (
    <>
      <path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H20v16H6.5A2.5 2.5 0 0 0 4 21.5z" />
      <path d="M8 7h8" />
    </>
  ),
  evaluation: (
    <>
      <path d="M9 11l3 3 8-8" />
      <path d="M20 12v7a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2h9" />
    </>
  ),
  achievement: (
    <path d="M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z" />
  ),
  goal: (
    <>
      <circle cx="12" cy="12" r="9" />
      <circle cx="12" cy="12" r="4" />
    </>
  ),
};

export default function ActivityTimeline({ items }: { items: ActivityItem[] }) {
  return (
    <section className="timeline" aria-labelledby="timeline-title">
      <h2 id="timeline-title" className="timeline__title">
        Actividad reciente
      </h2>

      <ol className="timeline__list">
        {items.map((item) => (
          <li key={item.id} className={`timeline__item timeline__item--${item.kind}`}>
            <span className="timeline__icon" aria-hidden="true">
              <svg viewBox="0 0 24 24">{ICONS[item.kind]}</svg>
            </span>
            <div className="timeline__body">
              <p className="timeline__name">{item.title}</p>
              <p className="timeline__detail">{item.detail}</p>
            </div>
            <span className="timeline__when">{item.when}</span>
          </li>
        ))}
      </ol>
    </section>
  );
}