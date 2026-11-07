import {
  PASSING_SCORE,
  formatShortDate,
  type Evaluation,
} from "../../services/resultsService";

export default function ResultsTable({
  evaluations,
}: {
  evaluations: Evaluation[];
}) {
  // La más reciente primero
  const rows = [...evaluations].reverse();

  return (
    <section className="panel" aria-labelledby="table-title">
      <div className="panel__head">
        <h2 id="table-title" className="panel__title">
          Historial de evaluaciones
        </h2>
      </div>

      <div className="table-wrap">
        <table className="results-table">
          <caption className="sr-only">
            Evaluaciones realizadas con su nota, intentos y errores
          </caption>
          <thead>
            <tr>
              <th scope="col">Evaluación</th>
              <th scope="col">Fecha</th>
              <th scope="col" className="num">Nota</th>
              <th scope="col" className="num">Intentos</th>
              <th scope="col" className="num">Errores</th>
              <th scope="col">Estado</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((e) => {
              const passed = e.score >= PASSING_SCORE;
              return (
                <tr key={e.id}>
                  <th scope="row">
                    <span className="results-table__title">{e.title}</span>
                    <span className="results-table__topic">{e.topic}</span>
                  </th>
                  <td>{formatShortDate(e.date)}</td>
                  <td className="num">
                    <strong>{e.score}%</strong>
                  </td>
                  <td className="num">{e.attempts}</td>
                  <td className="num">{e.errors}</td>
                  <td>
                    <span
                      className={`topic__chip ${
                        passed ? "topic__chip--strong" : "topic__chip--reinforce"
                      }`}
                    >
                      {passed ? "Aprobada" : "Reforzar"}
                    </span>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </section>
  );
}