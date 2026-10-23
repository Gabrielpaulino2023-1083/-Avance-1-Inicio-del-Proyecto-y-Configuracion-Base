import type { WeeklyHour } from "../../services/progressService";

export default function WeeklyHoursChart({ data }: { data: WeeklyHour[] }) {
  const max = Math.max(...data.map((d) => d.hours));
  const total = data.reduce((sum, d) => sum + d.hours, 0);

  return (
    <section className="panel" aria-labelledby="hours-title">
      <div className="panel__head">
        <h2 id="hours-title" className="panel__title">
          Horas de estudio esta semana
        </h2>
        <span className="panel__badge">{total} h en total</span>
      </div>

      <ul className="bars">
        {data.map((d) => (
          <li key={d.day} className="bars__item">
            <span className="bars__value">{d.hours}</span>
            <span className="bars__track">
              <span
                className={`bars__fill${d.hours === max ? " bars__fill--top" : ""}`}
                style={{ height: `${(d.hours / max) * 100}%` }}
                role="img"
                aria-label={`${d.day}: ${d.hours} horas`}
              />
            </span>
            <span className="bars__day">{d.day}</span>
          </li>
        ))}
      </ul>
    </section>
  );
}