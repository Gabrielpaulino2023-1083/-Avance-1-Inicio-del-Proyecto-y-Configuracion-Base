import { useEffect, useState } from "react";
import { useAuth } from "../../context/authContext";
import type { Exercise } from "../../services/contentService";
import { ApiError } from "../../services/http";
import {
  getRecommendation,
  type RecommendationResult,
} from "../../services/recommendationService";
import RecommendationCard from "../dashboard/RecommendationCard";

function formatTime(total: number) {
  const m = Math.floor(total / 60);
  const s = total % 60;
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}

export default function ExercisePanel({ exercise }: { exercise: Exercise }) {
  const { user, token, logout } = useAuth();
  const [selected, setSelected] = useState<number | null>(null);
  const [lastWrong, setLastWrong] = useState<number | null>(null);
  const [attempts, setAttempts] = useState(0);
  const [errors, setErrors] = useState(0);
  const [solved, setSolved] = useState(false);
  const [seconds, setSeconds] = useState(0);

  const [result, setResult] = useState<RecommendationResult | null>(null);
  const [asking, setAsking] = useState(false);
  const [askError, setAskError] = useState<string | null>(null);

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
    setResult(null);
    setAskError(null);
  }

  // Cierra el ciclo adaptativo: pide al motor una recomendación con lo
  // que el estudiante hizo en este ejercicio.
  async function askEngine() {
    setAsking(true);
    setAskError(null);
    try {
      setResult(
        await getRecommendation(token, user?.id ?? null, {
          topic: exercise.topic,
          attempts,
          errors,
          seconds,
        })
      );
    } catch (error) {
      if (error instanceof ApiError && error.status === 401) {
        logout();
        return;
      }
      setAskError(
        error instanceof Error
          ? error.message
          : "No se pudo obtener la recomendación."
      );
    } finally {
      setAsking(false);
    }
  }

  return (
    <div className="exercise-col">
      <section className="exercise" aria-labelledby="exercise-title">
        <div className="exercise__main">
          <span className="exercise__topic">Ejercicio · {exercise.topic}</span>
          <h2 id="exercise-title" className="exercise__question">
            {exercise.question}
          </h2>

          <div className="choices" role="radiogroup" aria-labelledby="exercise-title">
            {exercise.options.map((option, index) => {
              const isSelected = selected === index;
              const state =
                solved && index === exercise.correctIndex
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
              <>
                {!result && (
                  <button
                    type="button"
                    className="action"
                    onClick={askEngine}
                    disabled={asking}
                  >
                    {asking ? "Analizando..." : "Ver recomendación del motor"}
                  </button>
                )}
                <button
                  type="button"
                  className="action action--ghost"
                  onClick={restart}
                  disabled={asking}
                >
                  Repetir ejercicio
                </button>
              </>
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
            {askError && (
              <p className="feedback__box feedback__box--bad">
                <strong>No se pudo generar la recomendación.</strong> {askError}{" "}
                Puedes intentarlo de nuevo con el botón.
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

      {result && (
        <RecommendationCard
          recommendation={result.recommendation}
          evidence={result.evidence}
          showAction={false}
        />
      )}
    </div>
  );
}