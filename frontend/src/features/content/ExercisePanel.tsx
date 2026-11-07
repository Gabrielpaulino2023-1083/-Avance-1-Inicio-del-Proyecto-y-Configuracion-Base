import { useEffect, useState } from "react";
import type { Exercise } from "../../services/contentService";

function formatTime(total: number) {
  const m = Math.floor(total / 60);
  const s = total % 60;
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}

export default function ExercisePanel({ exercise }: { exercise: Exercise }) {
  const [selected, setSelected] = useState<number | null>(null);
  const [lastWrong, setLastWrong] = useState<number | null>(null);
  const [attempts, setAttempts] = useState(0);
  const [errors, setErrors] = useState(0);
  const [solved, setSolved] = useState(false);
  const [seconds, setSeconds] = useState(0);

  // El tiempo corre hasta que el estudiante acierta.
  useEffect(() => {
    if (solved) return;
    const id = setInterval(() => setSeconds((s) => s + 1), 1000);
    return () => clearInterval(id);
  }, [solved]);

  function check() {
    if (selected === null || solved) return;
    setAttempts((a) => a + 1);
    if (selected === exercise.correctIndex) {
      setSolved(true);
      setLastWrong(null);
    } else {
      setErrors((e) => e + 1);
      setLastWrong(selected);
    }
  }

  function restart() {
    setSelected(null);
    setLastWrong(null);
    setAttempts(0);
    setErrors(0);
    setSolved(false);
    setSeconds(0);
  }

  return (
    <section className="exercise" aria-labelledby="exercise-title">
      <div className="exercise__main">
        <span className="exercise__topic">Ejercicio · {exercise.topic}</span>
        <h2 id="exercise-title" className="exercise__question">
          {exercise.question}
        </h2>

        <div className="choices" role="radiogroup" aria-labelledby="exercise-title">
          {exercise.options.map((option, index) => {
            const isSelected = selected === index;
            const state = solved && index === exercise.correctIndex
              ? " choice--correct"
              : lastWrong === index && isSelected
                ? " choice--wrong"
                : isSelected
                  ? " choice--selected"
                  : "";
            return (
              <button
                key={option}
                type="button"
                role="radio"
                aria-checked={isSelected}
                disabled={solved}
                className={`choice${state}`}
                onClick={() => {
                  setSelected(index);
                  setLastWrong(null);
                }}
              >
                <span className="choice__letter">
                  {String.fromCharCode(65 + index)}
                </span>
                {option}
              </button>
            );
          })}
        </div>

        <div className="exercise__actions">
          {solved ? (
            <button type="button" className="action action--ghost" onClick={restart}>
              Repetir ejercicio
            </button>
          ) : (
            <button
              type="button"
              className="action"
              onClick={check}
              disabled={selected === null}
            >
              Comprobar respuesta
            </button>
          )}
        </div>

        <div className="feedback" role="status" aria-live="polite">
          {solved && (
            <p className="feedback__box feedback__box--ok">
              <strong>¡Correcto!</strong> {exercise.explanation}
            </p>
          )}
          {!solved && lastWrong !== null && (
            <p className="feedback__box feedback__box--bad">
              <strong>Todavía no.</strong> Revisa tu respuesta e inténtalo de nuevo.
            </p>
          )}
          {!solved && errors >= 2 && (
            <p className="feedback__box feedback__box--hint">
              <strong>Pista:</strong> {exercise.hint}
            </p>
          )}
        </div>
      </div>

      <aside className="metrics" aria-label="Tu actividad en este ejercicio">
        <h3 className="metrics__title">Tu actividad</h3>
        <dl className="metrics__list">
          <div>
            <dt>Tiempo</dt>
            <dd>{formatTime(seconds)}</dd>
          </div>
          <div>
            <dt>Intentos</dt>
            <dd>{attempts}</dd>
          </div>
          <div>
            <dt>Errores</dt>
            <dd>{errors}</dd>
          </div>
        </dl>
        <p className="metrics__note">
          Tiempo, intentos y errores son los datos con los que el motor
          adaptativo ajusta tus recomendaciones.
        </p>
      </aside>
    </section>
  );
}