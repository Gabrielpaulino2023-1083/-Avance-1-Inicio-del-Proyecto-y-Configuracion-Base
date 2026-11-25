import { useEffect, useState } from "react";
import { useAuth } from "../../context/authContext";
import { ApiError } from "../../services/http";
import {
  getQuestionnaire,
  listActivities,
  listEnrollments,
  listModules,
  listTopics,
  startAttempt,
  type ActivityApi,
  type Enrollment,
  type ModuleApi,
  type Questionnaire,
  type TopicApi,
} from "../../services/learningService";
import AttemptPanel from "./AttemptPanel";

interface ModuleWithTopics {
  module: ModuleApi;
  topics: TopicApi[];
}

interface ActiveAttempt {
  activity: ActivityApi;
  questionnaire: Questionnaire;
  key: string;
}

// El intento en curso se recuerda en el navegador para poder retomarlo
// si se recarga la página, sin gastar otra oportunidad.
function readSaved(key: string): number | null {
  try {
    const value = sessionStorage.getItem(key);
    return value ? Number(value) : null;
  } catch {
    return null;
  }
}
function writeSaved(key: string, id: number) {
  try {
    sessionStorage.setItem(key, String(id));
  } catch {
    /* sin almacenamiento: no se podrá retomar */
  }
}
function clearSaved(key: string) {
  try {
    sessionStorage.removeItem(key);
  } catch {
    /* nada que limpiar */
  }
}

// Contenido publicado del estudiante, leído de la API real:
// inscripción -> módulos -> temas -> actividades -> intento.
export default function RealCourse() {
  const { token, logout } = useAuth();
  const [enrollments, setEnrollments] = useState<Enrollment[] | null>(null);
  const [inscripcionId, setInscripcionId] = useState<number | null>(null);
  const [modules, setModules] = useState<ModuleWithTopics[] | null>(null);
  const [topic, setTopic] = useState<TopicApi | null>(null);
  const [activities, setActivities] = useState<ActivityApi[] | null>(null);
  const [attempt, setAttempt] = useState<ActiveAttempt | null>(null);
  const [starting, setStarting] = useState<number | null>(null);
  const [startError, setStartError] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const enrollment =
    enrollments?.find((e) => e.inscripcionId === inscripcionId) ?? null;
  const cursoId = enrollment?.cursoId ?? null;

  function fail(err: unknown) {
    if (err instanceof ApiError && err.status === 401) {
      logout();
      return;
    }
    setError(
      err instanceof Error ? err.message : "No se pudo cargar el contenido."
    );
  }

  // 1. Inscripciones del estudiante (de aquí sale el inscripcionId).
  useEffect(() => {
    if (!token) return;
    let active = true;
    listEnrollments(token)
      .then((data) => {
        if (!active) return;
        setEnrollments(data);
        if (data.length > 0) setInscripcionId(data[0].inscripcionId);
      })
      .catch((err) => active && fail(err));
    return () => {
      active = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token]);

  // 2. Módulos publicados del curso y los temas de cada uno.
  useEffect(() => {
    if (!token || cursoId === null) return;
    let active = true;
    setModules(null);
    setTopic(null);
    setActivities(null);
    setAttempt(null);
    listModules(token, cursoId)
      .then(async (mods) => {
        const full = await Promise.all(
          mods.map(async (m) => ({
            module: m,
            topics: await listTopics(token, m.id),
          }))
        );
        if (active) setModules(full);
      })
      .catch((err) => active && fail(err));
    return () => {
      active = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token, cursoId]);

  // 3. Actividades publicadas del tema elegido.
  function selectTopic(t: TopicApi) {
    if (!token || inscripcionId === null) return;
    setTopic(t);
    setActivities(null);
    setAttempt(null);
    setStartError(null);
    listActivities(token, inscripcionId, t.id)
      .then(setActivities)
      .catch(fail);
  }

  // 4. Inicia un intento (o retoma el que quedó en curso).
  async function begin(a: ActivityApi) {
    if (!token || inscripcionId === null) return;
    setStarting(a.id);
    setStartError(null);
    const key = `adaptativo.intento.${inscripcionId}.${a.id}`;
    try {
      let questionnaire: Questionnaire | null = null;
      const saved = readSaved(key);
      if (saved !== null) {
        try {
          questionnaire = await getQuestionnaire(token, saved);
        } catch {
          clearSaved(key);
        }
      }
      if (!questionnaire) {
        questionnaire = await startAttempt(token, inscripcionId, a.id);
        writeSaved(key, questionnaire.intentoId);
      }
      setAttempt({ activity: a, questionnaire, key });
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) {
        logout();
        return;
      }
      setStartError(
        err instanceof Error ? err.message : "No se pudo iniciar el intento."
      );
    } finally {
      setStarting(null);
    }
  }
    // Inicia la actividad que sugirió el backend, usando el flujo normal.
  function practiceSuggested(actividadId: number) {
    const target = activities?.find((x) => x.id === actividadId);
    if (!target) {
      setAttempt(null);
      setStartError("La actividad sugerida no está en la lista de este tema.");
      return;
    }
    begin(target);
  }

  if (error) {
    return (
      <p className="dash-state dash-state--error" role="alert">
        {error}
      </p>
    );
  }
  if (!enrollments) {
    return (
      <div className="dash-state" aria-busy="true">
        Cargando tus cursos...
      </div>
    );
  }
  if (enrollments.length === 0 || !enrollment) {
    return (
      <p className="dash-state">
        Aún no estás inscrito en ningún curso activo.
      </p>
    );
  }

  return (
    <div className="content-layout">
      <aside className="modules" aria-label="Contenido del curso">
        <div className="modules__head">
          {enrollments.length > 1 ? (
            <select
              className="rc-select"
              aria-label="Curso"
              value={inscripcionId ?? ""}
              onChange={(e) => setInscripcionId(Number(e.target.value))}
            >
              {enrollments.map((e) => (
                <option key={e.inscripcionId} value={e.inscripcionId}>
                  {e.curso}
                </option>
              ))}
            </select>
          ) : (
            <h2 className="modules__course">{enrollment.curso}</h2>
          )}
          <p className="modules__count">
            {enrollment.codigo} · Sección {enrollment.seccion}
          </p>
        </div>

        {!modules ? (
          <p className="modules__count">Cargando módulos...</p>
        ) : modules.length === 0 ? (
          <p className="modules__count">
            Este curso aún no tiene módulos publicados.
          </p>
        ) : (
          modules.map(({ module, topics }) => (
            <section key={module.id} className="module">
              <h3 className="module__title">{module.nombre}</h3>
              {topics.length === 0 ? (
                <p className="modules__count">Sin temas publicados.</p>
              ) : (
                <ul className="rc-list">
                  {topics.map((t) => (
                    <li key={t.id}>
                      <button
                        type="button"
                        className="rc-topic"
                        aria-current={topic?.id === t.id ? "true" : undefined}
                        onClick={() => selectTopic(t)}
                      >
                        {t.nombre}
                      </button>
                    </li>
                  ))}
                </ul>
              )}
            </section>
          ))
        )}
      </aside>

      <div className="exercise-col">
        {!topic ? (
          <p className="dash-state">
            Elige un tema para ver sus actividades.
          </p>
        ) : attempt ? (
          <AttemptPanel
            key={attempt.questionnaire.intentoId}
            title={attempt.activity.titulo}
            inscripcionId={inscripcionId ?? 0}
            temaId={topic.id}
            questionnaire={attempt.questionnaire}
            onExit={() => setAttempt(null)}
            onSubmitted={() => clearSaved(attempt.key)}
            onPractice={practiceSuggested}
          />
        ) : (
          <section className="reinforce" aria-labelledby="act-title">
            <h3 id="act-title" className="reinforce__title">
              Actividades · {topic.nombre}
            </h3>
            {activities === null ? (
              <p className="reinforce__note">Cargando actividades...</p>
            ) : activities.length === 0 ? (
              <p className="reinforce__note">
                Este tema no tiene actividades publicadas.
              </p>
            ) : (
              <ul className="rc-list">
                {activities.map((a) => (
                  <li key={a.id} className="rc-act">
                    <span>
                      <strong>{a.titulo}</strong>
                      <small>
                        {a.duracionMinutos
                          ? `${a.duracionMinutos} min`
                          : "Sin límite de tiempo"}
                        {a.maxIntentos
                          ? ` · máx. ${a.maxIntentos} intentos`
                          : ""}
                        {a.disponibleAhora ? "" : " · No disponible ahora"}
                      </small>
                    </span>
                    <button
                      type="button"
                      className="action"
                      disabled={!a.disponibleAhora || starting !== null}
                      onClick={() => begin(a)}
                    >
                      {starting === a.id ? "Iniciando..." : "Iniciar"}
                    </button>
                  </li>
                ))}
              </ul>
            )}
            {startError && (
              <p className="feedback__box feedback__box--bad" role="alert">
                {startError}
              </p>
            )}
          </section>
        )}
      </div>
    </div>
  );
}