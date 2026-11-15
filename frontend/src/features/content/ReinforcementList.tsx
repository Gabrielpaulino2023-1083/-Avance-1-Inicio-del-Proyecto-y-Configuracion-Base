import type { CourseModule } from "../../services/contentService";
import type { Recommendation } from "../../types";

interface Props {
  action: Recommendation["action"];
  topic: string;
  modules: CourseModule[];
}

export default function ReinforcementList({ action, topic, modules }: Props) {
  const lessons = modules.flatMap((m) =>
    m.lessons.map((l) => ({ ...l, module: m.title }))
  );
  const reinforce = action === "reinforce_topic";
  const words = topic
    .toLowerCase()
    .split(/\s+/)
    .filter((w) => w.length >= 4);

  const items = reinforce
    ? lessons.filter(
        (l) =>
          l.kind === "lesson" &&
          words.some((w) => l.title.toLowerCase().includes(w))
      )
    : lessons.filter((l) => l.status === "pending");

  if (items.length === 0) return null;

  return (
    <section className="reinforce" aria-labelledby="reinforce-title">
      <h3 id="reinforce-title" className="reinforce__title">
        {reinforce ? "Material de refuerzo" : "Para seguir avanzando"}
      </h3>
      <ul className="reinforce__list">
        {items.map((l) => (
          <li key={l.id} className="reinforce__item">
            <span>{l.title}</span>
            <small>
              {l.module} · {l.minutes} min
            </small>
          </li>
        ))}
      </ul>
      <p className="reinforce__note">
        Contenido de ejemplo: las lecciones se podrán abrir cuando el backend
        tenga contenidos.
      </p>
    </section>
  );
}