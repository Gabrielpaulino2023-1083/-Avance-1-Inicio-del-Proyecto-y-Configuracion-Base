import {
  PASSING_SCORE,
  formatShortDate,
  type Evaluation,
} from "../../services/resultsService";

const WIDTH = 600;
const HEIGHT = 230;
const LEFT = 44;
const RIGHT = 576;
const TOP = 20;
const BOTTOM = 186;
const GRID = [0, 25, 50, 75, 100];

function xAt(index: number, total: number) {
  return total === 1
    ? (LEFT + RIGHT) / 2
    : LEFT + (index * (RIGHT - LEFT)) / (total - 1);
}

function yAt(score: number) {
  return BOTTOM - (score / 100) * (BOTTOM - TOP);
}

export default function ScoreTrend({
  evaluations,
}: {
  evaluations: Evaluation[];
}) {
  const points = evaluations.map((e, i) => ({
    x: xAt(i, evaluations.length),
    y: yAt(e.score),
    evaluation: e,
  }));
  const path = points
    .map((p, i) => `${i === 0 ? "M" : "L"}${p.x},${p.y}`)
    .join(" ");

  return (
    <section className="panel" aria-labelledby="trend-title">
      <div className="panel__head">
        <h2 id="trend-title" className="panel__title">
          Evolución de tus notas
        </h2>
        <span className="panel__badge">Mínimo para aprobar: {PASSING_SCORE}%</span>
      </div>

      <svg
        className="trend"
        viewBox={`0 0 ${WIDTH} ${HEIGHT}`}
        role="img"
        aria-label={`Notas por evaluación: ${evaluations
          .map((e) => `${e.title} ${e.score}%`)
          .join(", ")}`}
      >
        {GRID.map((value) => (
          <g key={value}>
            <line
              className="trend__grid"
              x1={LEFT}
              x2={RIGHT}
              y1={yAt(value)}
              y2={yAt(value)}
            />
            <text className="trend__axis" x={LEFT - 10} y={yAt(value) + 4} textAnchor="end">
              {value}
            </text>
          </g>
        ))}

        <line
          className="trend__pass"
          x1={LEFT}
          x2={RIGHT}
          y1={yAt(PASSING_SCORE)}
          y2={yAt(PASSING_SCORE)}
        />

        <path className="trend__line" d={path} />

        {points.map((p) => (
          <g key={p.evaluation.id}>
            <circle
              className={`trend__dot${
                p.evaluation.score < PASSING_SCORE ? " trend__dot--low" : ""
              }`}
              cx={p.x}
              cy={p.y}
              r={6}
            />
            <text className="trend__axis" x={p.x} y={HEIGHT - 12} textAnchor="middle">
              {formatShortDate(p.evaluation.date)}
            </text>
          </g>
        ))}
      </svg>
    </section>
  );
}