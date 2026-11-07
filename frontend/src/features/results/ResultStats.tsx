import type { Evaluation } from "../../services/resultsService";

export default function ResultStats({
  evaluations,
}: {
  evaluations: Evaluation[];
}) {
  const scores = evaluations.map((e) => e.score);
  const average = Math.round(scores.reduce((a, b) => a + b, 0) / scores.length);
  const best = evaluations.reduce((top, e) => (e.score > top.score ? e : top));

  return (
    <ul className="result-stats">
      <li className="result-stat">
        <span className="result-stat__label">Promedio general</span>
        <strong className="result-stat__value">{average}%</strong>
        <span className="result-stat__note">
          en {evaluations.length} evaluaciones
        </span>
      </li>
      <li className="result-stat">
        <span className="result-stat__label">Mejor resultado</span>
        <strong className="result-stat__value">{best.score}%</strong>
        <span className="result-stat__note">{best.title}</span>
      </li>
      <li className="result-stat">
        <span className="result-stat__label">Evaluaciones realizadas</span>
        <strong className="result-stat__value">{evaluations.length}</strong>
        <span className="result-stat__note">desde el inicio del curso</span>
      </li>
    </ul>
  );
}