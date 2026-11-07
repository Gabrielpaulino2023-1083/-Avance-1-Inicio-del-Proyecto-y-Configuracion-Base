import type { CourseModule, Lesson } from "../../services/contentService";

const STATUS_LABEL: Record<Lesson["status"], string> = {
  done: "Completada",
  current: "En curso",
  pending: "Pendiente",
};

export default function ModuleList({
  courseName,
  modules,
}: {
  courseName: string;
  modules: CourseModule[];
}) {
  const all = modules.flatMap((m) => m.lessons);
  const done = all.filter((l) => l.status === "done").length;

  return (
    <aside className="modules" aria-label="Contenido del curso">
      <div className="modules__head">
        <h2 className="modules__course">{courseName}</h2>
        <p className="modules__count">
          {done} de {all.length} lecciones completadas
        </p>
        <div className="modules__bar" aria-hidden="true">
          <span style={{ width: `${(done / all.length) * 100}%` }} />
        </div>
      </div>

      {modules.map((m) => (
        <section key={m.id} className="module">
          <h3 className="module__title">{m.title}</h3>
          <ul className="module__lessons">
            {m.lessons.map((l) => (
              <li
                key={l.id}
                className={`lesson lesson--${l.status}`}
                aria-current={l.status === "current" ? "step" : undefined}
              >
                <span className="lesson__dot" aria-hidden="true" />
                <span className="lesson__text">
                  <span className="lesson__name">{l.title}</span>
                  <span className="lesson__meta">
                    {l.kind === "exercise" ? "Ejercicio" : "Lección"} ·{" "}
                    {l.minutes} min · {STATUS_LABEL[l.status]}
                  </span>
                </span>
              </li>
            ))}
          </ul>
        </section>
      ))}
    </aside>
  );
}