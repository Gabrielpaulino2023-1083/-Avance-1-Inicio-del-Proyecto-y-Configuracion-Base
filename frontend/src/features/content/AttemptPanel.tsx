import { useState } from "react";
import { useAuth } from "../../context/authContext";
import { ApiError } from "../../services/http";
import {
  getTopicRecommendation,
  saveSelection,
  submitAttempt,
  type AttemptResult,
  type Question,
  type Questionnaire,
  type SuggestedActivity,
} from "../../services/learningService";
import type { Recommendation, RecommendationEvidence } from "../../types";
import RecommendationCard from "../dashboard/RecommendationCard";

const ACTIONS: Recommendation["action"][] = [
  "reinforce_topic",
  "increase_difficulty",
  "maintain_difficulty",
];
const DIFFICULTIES: Recommendation["difficulty"][] = [
  "reduced",
  "increased",
  "current",
];

interface Props {
  title: string;
    inscripcionId: number;
  temaId: number;
  questionnaire: Questionnaire;
  onExit: () => void; // volver a la lista de actividades
  onSubmitted: () => void; // el intento ya no está en curso
    onPractice?: (actividadId: number) => void; // iniciar la actividad sugerida
}

function formatTime(iso: string) {
  return new Date(iso).toLocaleTimeString("es-DO", {
    hour: "2-digit",
    minute: "2-digit",
  });
}

// Cuestionario de un intento real. El backend califica; aquí nunca se
// calcula una nota ni se conoce la respuesta correcta.
export default function AttemptPanel({
  title,
  inscripcionId,
  temaId,
  questionnaire,
  onExit,
  onSubmitted,
  onPractice,
}: Props) {
  const { user, token, logout } = useAuth();
  const [answers, setAnswers] = useState<Record<number, number[]>>(() =>
    Object.fromEntries(
      questionnaire.preguntas.map((q) => [q.respuestaId, q.opcionesSeleccionadas])
    )
  );
  const [message, setMessage] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [result, setResult] = useState<AttemptResult | null>(null);
  const [rec, setRec] = useState<{
    recommendation: Recommendation;
    evidence: RecommendationEvidence;
  } | null>(null);
  const [asking, setAsking] = useState(false);
  const [noData, setNoData] = useState(false);  
  const [suggested, setSuggested] = useState<SuggestedActivity | null>(null);

  function fail(err: unknown, fallback: string) {
    if (err instanceof ApiError && err.status === 401) {
      logout();
      return;
    }
    setMessage(err instanceof Error ? err.message : fallback);
  }

  // Guarda la selección en el servidor cada vez que cambia.
  function choose(q: Question, optionId: number) {
    if (!token || result) return;
    const current = answers[q.respuestaId] ?? [];
    const next =
      q.tipo === "SELECCION_MULTIPLE"
        ? current.includes(optionId)
          ? current.filter((x) => x !== optionId)
          : [...current, optionId]
        : [optionId];
    setAnswers((a) => ({ ...a, [q.respuestaId]: next }));
    setMessage(null);
    saveSelection(token, q.respuestaId, next).catch((err) => {
      setAnswers((a) => ({ ...a, [q.respuestaId]: current }));
      fail(err, "No se pudo guardar tu respuesta.");
    });
  }

  async function submit() {
    if (!token || submitting) return;
    const pending = questionnaire.preguntas.filter(
      (q) => (answers[q.respuestaId] ?? []).length === 0
    ).length;
    if (
      pending > 0 &&
      !window.confirm(
        `Te faltan ${pending} pregunta(s) sin responder. ¿Entregar de todos modos?`
      )
    ) {
      return;
    }
    setSubmitting(true);
    setMessage(null);
    try {
      setResult(await submitAttempt(token, questionnaire.intentoId));
      onSubmitted();
    } catch (err) {
      fail(err, "No se pudo entregar el intento.");
    } finally {
      setSubmitting(false);
    }
  }

    // Pide al motor una recomendación con los intentos calificados del tema.
  async function askEngine() {
    if (!token) return;
    setAsking(true);
    setMessage(null);
    setNoData(false);
    try {
      const r = await getTopicRecommendation(token, inscripcionId, temaId);
      const action = ACTIONS.find((a) => a === r.accion);
      const difficulty = DIFFICULTIES.find((d) => d === r.dificultad);
      if (
        !action ||
        !difficulty ||
        typeof r.recomendacion !== "string" ||
        !Number.isFinite(r.mastery) ||
        !Number.isFinite(r.errors) ||
        !Number.isFinite(r.attempts)
      ) {
        throw new Error("El servidor devolvió una respuesta incompleta o inválida.");
      }
      setRec({
        recommendation: {
          student_id: user?.id ?? 0,
          topic: r.tema,
          action,
          difficulty,
          reason: `Dominio: ${r.mastery}%; errores: ${r.errors}; intentos: ${r.attempts}.`,
          recommendation: r.recomendacion,
        },
        evidence: { mastery: r.mastery, errors: r.errors, attempts: r.attempts },
      });
        setSuggested(r.actividadSugerida ?? null);
    } catch (err) {
      if (err instanceof ApiError && err.status === 404) {
        setNoData(true);
      } else {
        fail(err, "No se pudo obtener la recomendación.");
      }
    } finally {
      setAsking(false);
    }
  }

  if (result) {
    return (
      <section className="reinforce rc-stack" aria-labelledby="result-title">
        <h3 id="result-title" className="reinforce__title">
          Resultado · {title}
        </h3>
        <p className="feedback__box feedback__box--ok">
          <strong>
            {result.porcentaje === null ? "Sin nota" : `${result.porcentaje}%`}
          </strong>
          {result.puntajeObtenido !== null && result.puntajeMaximo !== null
            ? ` · ${result.puntajeObtenido} de ${result.puntajeMaximo} puntos`
            : ""}
        </p>
        {result.motivoEntrega === "VENCIMIENTO" && (
          <p className="feedback__box feedback__box--hint">
            El intento se entregó automáticamente porque venció el tiempo.
          </p>
        )}
               <div className="exercise__actions">
          {!rec && (
            <button
              type="button"
              className="action"
              onClick={askEngine}
              disabled={asking}
            >
              {asking ? "Analizando..." : "Ver recomendación del motor"}
            </button>
          )}
          <button type="button" className="action action--ghost" onClick={onExit}>
            {rec?.recommendation.action === "reinforce_topic"
              ? "Practicar otra actividad de este tema"
              : "Volver a las actividades"}
          </button>
        </div>
        {noData && (
          <p className="feedback__box feedback__box--hint">
            <strong>Sin datos suficientes todavía.</strong> Aún no tienes
            intentos calificados en este tema, así que el motor no puede
            analizar tu desempeño.
          </p>
        )}
        {message && (
          <p className="feedback__box feedback__box--bad" role="alert">
            <strong>No se pudo generar la recomendación.</strong> {message}
          </p>
        )}
        {rec && (
          <>
            <RecommendationCard
              recommendation={rec.recommendation}
              evidence={rec.evidence}
              showAction={false}
            />
            <p className="feedback__box feedback__box--hint">
              {rec.recommendation.action === "reinforce_topic"
                ? "Refuerzo: vuelve a las actividades de este tema y practica de nuevo. Cuando entregues otro intento, el motor recalcula tu recomendación."
                : rec.recommendation.action === "increase_difficulty"
                  ? "Para seguir avanzando: elige otro tema o una actividad más retadora."
                  : "Sigue practicando este tema para mantener tu nivel."}
            </p>
                        {suggested && onPractice && (
              <div className="feedback__box feedback__box--hint rc-stack">
                <p>
                  <strong>Actividad sugerida:</strong> {suggested.titulo} ·
                  dificultad {suggested.dificultad.toLowerCase()}
                </p>
                {!suggested.coincideNivel && (
                  <p>
                    No hay una actividad del nivel exacto que buscaba el motor;
                    esta es la más cercana disponible.
                  </p>
                )}
                {suggested.esRepeticion && (
                  <p>Es la misma actividad que acabas de hacer.</p>
                )}
                <div className="exercise__actions">
                  <button
                    type="button"
                    className="action"
                    onClick={() => onPractice(suggested.actividadId)}
                  >
                    Practicar esta actividad
                  </button>
                </div>
              </div>
            )}
          </>
        )}
      </section>
    );
  }

  return (
    <section className="reinforce" aria-labelledby="attempt-title">
      <h3 id="attempt-title" className="reinforce__title">
        {title}
      </h3>
      {questionnaire.instrucciones && (
        <p className="reinforce__note">{questionnaire.instrucciones}</p>
      )}
      {questionnaire.venceEn && (
        <p className="reinforce__note">
          Debes entregar antes de las {formatTime(questionnaire.venceEn)}.
        </p>
      )}

      {questionnaire.preguntas.map((q, i) => {
        const multiple = q.tipo === "SELECCION_MULTIPLE";
        const selected = answers[q.respuestaId] ?? [];
        return (
          <fieldset key={q.preguntaId} className="rc-question">
            <legend className="exercise__question">
              {i + 1}. {q.enunciado}
            </legend>
            {multiple && (
              <p className="reinforce__note">Puedes marcar varias opciones.</p>
            )}
            <div className="choices">
              {q.opciones.map((o, k) => {
                const isSelected = selected.includes(o.id);
                return (
                  <button
                    key={o.id}
                    type="button"
                    role={multiple ? "checkbox" : "radio"}
                    aria-checked={isSelected}
                    className={`choice${isSelected ? " choice--selected" : ""}`}
                    onClick={() => choose(q, o.id)}
                  >
                    <span className="choice__letter">
                      {String.fromCharCode(65 + k)}
                    </span>
                    {o.texto}
                  </button>
                );
              })}
            </div>
          </fieldset>
        );
      })}

      {message && (
        <p className="feedback__box feedback__box--bad" role="alert">
          {message}
        </p>
      )}

      <div className="exercise__actions">
        <button
          type="button"
          className="action"
          onClick={submit}
          disabled={submitting}
        >
          {submitting ? "Entregando..." : "Entregar intento"}
        </button>
        <button
          type="button"
          className="action action--ghost"
          onClick={onExit}
          disabled={submitting}
        >
          Salir (puedes retomarlo)
        </button>
      </div>
    </section>
  );
}