import { useEffect, useState } from "react";
import { Navigate } from "react-router-dom";
import { useAuth } from "../../context/authContext";
import CursoForm from "../../features/courses/CursoForm";
import {
  changeCursoEstado,
  createCurso,
  listCursos,
  updateCurso,
} from "../../services/courseService";
import { ApiError } from "../../services/http";
import {
  ESTADOS_CURSO,
  type Curso,
  type CursoInput,
  type EstadoCurso,
} from "../../types/course";
import "../../features/dashboard/dashboard.css";
import "../../features/progress/progress.css";
import "../../features/manage/manage.css";

type Filter = "TODOS" | EstadoCurso;
type Notice = { ok: boolean; text: string };

const label = (estado: string) =>
  estado.charAt(0) + estado.slice(1).toLowerCase();

const formatDate = (iso: string) =>
  new Date(iso).toLocaleDateString("es-DO", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });

function Badge({ estado }: { estado: EstadoCurso }) {
  return (
    <span className={`mg-badge mg-badge--${estado.toLowerCase()}`}>
      {estado}
    </span>
  );
}

export default function CoursesScreen() {
  const { user, token, logout } = useAuth();
  const [cursos, setCursos] = useState<Curso[] | null>(null);
  const [filter, setFilter] = useState<Filter>("TODOS");
  const [dialog, setDialog] = useState<{ item: Curso | null } | null>(null);
  const [archiving, setArchiving] = useState<Curso | null>(null);
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState<Notice | null>(null);

  function fail(error: unknown) {
    // Sesión vencida: se cierra y ProtectedRoute lleva al login.
    if (error instanceof ApiError && error.status === 401) {
      logout();
      return;
    }
    setNotice({
      ok: false,
      text:
        error instanceof Error ? error.message : "Ocurrió un error inesperado.",
    });
  }

  useEffect(() => {
    let active = true;
    listCursos(token)
      .then((data) => {
        if (active) setCursos(data);
      })
      .catch((error) => {
        if (!active) return;
        setCursos([]);
        fail(error);
      });
    return () => {
      active = false;
    };
    // eslint-disable-next-line
  }, [token]);

  // El aviso se esconde solo.
  useEffect(() => {
    if (!notice) return;
    const timer = setTimeout(() => setNotice(null), 4500);
    return () => clearTimeout(timer);
  }, [notice]);

  // Solo el ADMINISTRADOR administra cursos.
  if (user && user.rol !== "ADMINISTRADOR") {
    return <Navigate to="/" replace />;
  }

  async function refresh() {
    setCursos(await listCursos(token));
  }

  async function saveCurso(values: CursoInput) {
    const editing = dialog?.item ?? null;
    if (editing) await updateCurso(token, editing.id, values);
    else await createCurso(token, values);
    await refresh();
    setDialog(null);
    setNotice({
      ok: true,
      text: editing ? "Curso actualizado." : "Curso creado en estado Borrador.",
    });
  }

  async function setEstado(curso: Curso, estado: "ACTIVO" | "ARCHIVADO") {
    setBusy(true);
    try {
      await changeCursoEstado(token, curso.id, estado);
      await refresh();
      setNotice({
        ok: true,
        text: estado === "ACTIVO" ? "Curso activado." : "Curso archivado.",
      });
    } catch (error) {
      fail(error); // p. ej. archivar un curso con ediciones abiertas (409)
    } finally {
      setBusy(false);
      setArchiving(null);
    }
  }

  if (!cursos) {
    return (
      <div className="dash-state" aria-busy="true">
        Cargando cursos...
      </div>
    );
  }

  const visible =
    filter === "TODOS" ? cursos : cursos.filter((c) => c.estado === filter);
  const count = (estado: EstadoCurso) =>
    cursos.filter((c) => c.estado === estado).length;

  return (
    <div className="dash">
      <header className="page-head">
        <h1>Gestión de cursos</h1>
        <p>
          Crea, edita, activa y archiva los cursos de la plataforma. Eliminar un
          curso significa archivarlo, para conservar su historial.
        </p>
      </header>

      <ul className="mg-stats">
        <li className="mg-stat">
          <span>Cursos</span>
          <strong>{cursos.length}</strong>
        </li>
        <li className="mg-stat">
          <span>Activos</span>
          <strong>{count("ACTIVO")}</strong>
        </li>
        <li className="mg-stat">
          <span>En borrador</span>
          <strong>{count("BORRADOR")}</strong>
        </li>
        <li className="mg-stat">
          <span>Archivados</span>
          <strong>{count("ARCHIVADO")}</strong>
        </li>
      </ul>

      <div className="mg-toolbar">
        <div className="mg-filters" role="group" aria-label="Filtrar por estado">
          {(["TODOS", ...ESTADOS_CURSO] as Filter[]).map((f) => (
            <button
              key={f}
              type="button"
              className="mg-chip"
              aria-pressed={filter === f}
              onClick={() => setFilter(f)}
            >
              {label(f)}
            </button>
          ))}
        </div>
        <button
          type="button"
          className="mg-btn mg-btn--primary"
          onClick={() => setDialog({ item: null })}
        >
          + Nuevo curso
        </button>
      </div>

      {notice && (
        <p
          className={`mg-notice ${notice.ok ? "mg-notice--ok" : "mg-notice--error"}`}
          role="status"
        >
          {notice.text}
        </p>
      )}

      {visible.length === 0 ? (
        <p className="mg-empty">
          No hay cursos en este estado. Crea uno con “Nuevo curso”.
        </p>
      ) : (
        <ul className="mg-list">
          {visible.map((c) => (
            <li key={c.id} className="mg-item">
              <div className="mg-item__row">
                <span className="mg-order" aria-label={`Curso ${c.id}`}>
                  {c.id}
                </span>

                <div className="mg-item__main">
                  <h3>
                    {c.nombre} <Badge estado={c.estado} />
                  </h3>
                  <p>{c.descripcion}</p>
                  <div className="mg-item__meta">
                    Código {c.codigo} · Actualizado {formatDate(c.actualizadoEn)}
                  </div>
                </div>

                <div className="mg-actions">
                  {c.estado === "BORRADOR" && (
                    <button
                      type="button"
                      className="mg-btn mg-btn--small mg-btn--primary"
                      disabled={busy}
                      onClick={() => setEstado(c, "ACTIVO")}
                    >
                      Activar
                    </button>
                  )}
                  {c.estado !== "ARCHIVADO" && (
                    <>
                      <button
                        type="button"
                        className="mg-btn mg-btn--small"
                        onClick={() => setDialog({ item: c })}
                      >
                        Editar
                      </button>
                      <button
                        type="button"
                        className="mg-btn mg-btn--small mg-btn--danger"
                        onClick={() => setArchiving(c)}
                      >
                        Archivar
                      </button>
                    </>
                  )}
                  {c.estado === "ARCHIVADO" && (
                    <span className="mg-item__meta">Solo lectura</span>
                  )}
                </div>
              </div>
            </li>
          ))}
        </ul>
      )}

      {dialog && (
        <CursoForm
          key={dialog.item?.id ?? "nuevo-curso"}
          title={dialog.item ? "Editar curso" : "Nuevo curso"}
          submitLabel={dialog.item ? "Guardar cambios" : "Crear curso"}
          initial={
            dialog.item
              ? {
                  codigo: dialog.item.codigo,
                  nombre: dialog.item.nombre,
                  descripcion: dialog.item.descripcion,
                }
              : { codigo: "", nombre: "", descripcion: "" }
          }
          onSubmit={saveCurso}
          onClose={() => setDialog(null)}
        />
      )}

      {archiving && (
        <div
          className="mg-overlay"
          onMouseDown={(event) => {
            if (event.target === event.currentTarget && !busy) setArchiving(null);
          }}
        >
          <div className="mg-dialog" role="alertdialog" aria-modal="true">
            <h2>¿Archivar curso?</h2>
            <p>
              Vas a archivar “{archiving.nombre}”. Un curso archivado queda en
              solo lectura y no se puede editar ni reactivar.
            </p>
            <div className="mg-dialog__actions">
              <button
                type="button"
                className="mg-btn"
                onClick={() => setArchiving(null)}
                disabled={busy}
              >
                Cancelar
              </button>
              <button
                type="button"
                className="mg-btn mg-btn--danger"
                onClick={() => setEstado(archiving, "ARCHIVADO")}
                disabled={busy}
              >
                {busy ? "Archivando..." : "Sí, archivar"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}