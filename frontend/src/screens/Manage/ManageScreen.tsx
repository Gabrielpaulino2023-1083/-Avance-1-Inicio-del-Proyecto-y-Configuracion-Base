import { useEffect, useState } from "react";
import { Navigate } from "react-router-dom";
import { useAuth } from "../../context/authContext";
import ContenidoForm from "../../features/manage/ContenidoForm";
import {
  createModulo,
  createTema,
  deleteModulo,
  deleteTema,
  listModulos,
  listTemas,
  updateModulo,
  updateTema,
} from "../../services/curriculumService";
import { ApiError } from "../../services/http";
import {
  ESTADOS,
  type ContenidoInput,
  type EstadoContenido,
  type Modulo,
  type Tema,
} from "../../types/curriculum";
import "../../features/dashboard/dashboard.css";
import "../../features/progress/progress.css";
import "../../features/manage/manage.css";

type Filter = "TODOS" | EstadoContenido;
type Dialog =
  | { kind: "modulo"; item: Modulo | null }
  | { kind: "tema"; modulo: Modulo; item: Tema | null };
type Confirm = { kind: "modulo" | "tema"; id: number; nombre: string };
type Notice = { ok: boolean; text: string };

const label = (estado: string) =>
  estado.charAt(0) + estado.slice(1).toLowerCase();

const formatDate = (iso: string) =>
  new Date(iso).toLocaleDateString("es-DO", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });

function Badge({ estado }: { estado: EstadoContenido }) {
  return (
    <span className={`mg-badge mg-badge--${estado.toLowerCase()}`}>
      {estado}
    </span>
  );
}

export default function ManageScreen() {
  const { user, token, logout } = useAuth();
  const [modulos, setModulos] = useState<Modulo[] | null>(null);
  const [filter, setFilter] = useState<Filter>("TODOS");
  const [openId, setOpenId] = useState<number | null>(null);
  const [temas, setTemas] = useState<Tema[]>([]);
  const [temasLoading, setTemasLoading] = useState(false);
  const [dialog, setDialog] = useState<Dialog | null>(null);
  const [confirm, setConfirm] = useState<Confirm | null>(null);
  const [deleting, setDeleting] = useState(false);
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
    listModulos(token)
      .then((data) => {
        if (active) setModulos(data);
      })
      .catch((error) => {
        if (!active) return;
        setModulos([]);
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

  // Solo DOCENTE y ADMINISTRADOR gestionan contenido.
  if (user && user.rol === "ESTUDIANTE") {
    return <Navigate to="/" replace />;
  }

  async function refresh() {
    setModulos(await listModulos(token));
  }

  async function loadTemas(id: number) {
    setTemasLoading(true);
    try {
      setTemas(await listTemas(token, id));
    } catch (error) {
      fail(error);
    } finally {
      setTemasLoading(false);
    }
  }

  function toggle(modulo: Modulo) {
    if (openId === modulo.id) {
      setOpenId(null);
      return;
    }
    setOpenId(modulo.id);
    setTemas([]);
    void loadTemas(modulo.id);
  }

  // ---------- Guardar (crear / editar) ----------

  async function saveModulo(values: ContenidoInput) {
    const editing = dialog?.kind === "modulo" ? dialog.item : null;
    if (editing) await updateModulo(token, editing.id, values);
    else await createModulo(token, values);
    await refresh();
    setDialog(null);
    setNotice({
      ok: true,
      text: editing ? "Módulo actualizado." : "Módulo creado.",
    });
  }

  async function saveTema(values: ContenidoInput) {
    if (dialog?.kind !== "tema") return;
    const { modulo, item } = dialog;
    if (item) await updateTema(token, modulo.id, item.id, values);
    else await createTema(token, modulo.id, values);
    await Promise.all([refresh(), loadTemas(modulo.id)]);
    setDialog(null);
    setNotice({ ok: true, text: item ? "Tema actualizado." : "Tema creado." });
  }

  // ---------- Cambiar estado desde la lista ----------

  async function changeModuloEstado(m: Modulo, estado: EstadoContenido) {
    try {
      await updateModulo(token, m.id, {
        nombre: m.nombre,
        descripcion: m.descripcion,
        orden: m.orden,
        estado,
      });
      await refresh();
      setNotice({ ok: true, text: `Módulo en estado ${label(estado)}.` });
    } catch (error) {
      fail(error);
    }
  }

  async function changeTemaEstado(t: Tema, estado: EstadoContenido) {
    try {
      await updateTema(token, t.moduloId, t.id, {
        nombre: t.nombre,
        descripcion: t.descripcion,
        orden: t.orden,
        estado,
      });
      await loadTemas(t.moduloId);
      setNotice({ ok: true, text: `Tema en estado ${label(estado)}.` });
    } catch (error) {
      fail(error);
    }
  }

  // ---------- Eliminar ----------

  async function runDelete() {
    if (!confirm) return;
    setDeleting(true);
    try {
      if (confirm.kind === "modulo") {
        await deleteModulo(token, confirm.id);
        if (openId === confirm.id) setOpenId(null);
      } else {
        await deleteTema(token, confirm.id);
        if (openId !== null) await loadTemas(openId);
      }
      await refresh();
      setNotice({
        ok: true,
        text: confirm.kind === "modulo" ? "Módulo eliminado." : "Tema eliminado.",
      });
    } catch (error) {
      fail(error); // p. ej. módulo con temas (la base de datos lo impide)
    } finally {
      setDeleting(false);
      setConfirm(null);
    }
  }

  if (!modulos) {
    return (
      <div className="dash-state" aria-busy="true">
        Cargando módulos...
      </div>
    );
  }

  const visible =
    filter === "TODOS" ? modulos : modulos.filter((m) => m.estado === filter);
  const count = (estado: EstadoContenido) =>
    modulos.filter((m) => m.estado === estado).length;

  const nextModuloOrden = modulos.reduce((max, m) => Math.max(max, m.orden), 0) + 1;
  const nextTemaOrden = temas.reduce((max, t) => Math.max(max, t.orden), 0) + 1;

  return (
    <div className="dash">
      <header className="page-head">
        <h1>Gestión de contenido</h1>
        <p>
          Crea y organiza los módulos y temas del curso. Los cambios se guardan
          como datos simulados mientras se conecta el backend.
        </p>
      </header>

      <ul className="mg-stats">
        <li className="mg-stat">
          <span>Módulos</span>
          <strong>{modulos.length}</strong>
        </li>
        <li className="mg-stat">
          <span>Publicados</span>
          <strong>{count("PUBLICADO")}</strong>
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
          {(["TODOS", ...ESTADOS] as Filter[]).map((f) => (
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
          onClick={() => setDialog({ kind: "modulo", item: null })}
        >
          + Nuevo módulo
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
          No hay módulos en este estado. Crea uno con “Nuevo módulo”.
        </p>
      ) : (
        <ul className="mg-list">
          {visible.map((m) => (
            <li key={m.id} className="mg-item">
              <div className="mg-item__row">
                <span className="mg-order" aria-label={`Orden ${m.orden}`}>
                  {m.orden}
                </span>

                <div className="mg-item__main">
                  <h3>
                    {m.nombre} <Badge estado={m.estado} />
                  </h3>
                  <p>{m.descripcion}</p>
                  <div className="mg-item__meta">
                    {m.totalTemas} {m.totalTemas === 1 ? "tema" : "temas"} ·
                    Actualizado {formatDate(m.actualizadoEn)}
                  </div>
                </div>

                <div className="mg-actions">
                  <select
                    className="mg-select"
                    aria-label={`Estado de ${m.nombre}`}
                    value={m.estado}
                    onChange={(e) =>
                      changeModuloEstado(m, e.target.value as EstadoContenido)
                    }
                  >
                    {ESTADOS.map((s) => (
                      <option key={s} value={s}>
                        {label(s)}
                      </option>
                    ))}
                  </select>
                  <button
                    type="button"
                    className="mg-btn mg-btn--small"
                    onClick={() => toggle(m)}
                    aria-expanded={openId === m.id}
                  >
                    {openId === m.id ? "Ocultar temas" : "Ver temas"}
                  </button>
                  <button
                    type="button"
                    className="mg-btn mg-btn--small"
                    onClick={() => setDialog({ kind: "modulo", item: m })}
                  >
                    Editar
                  </button>
                  <button
                    type="button"
                    className="mg-btn mg-btn--small mg-btn--danger"
                    onClick={() =>
                      setConfirm({ kind: "modulo", id: m.id, nombre: m.nombre })
                    }
                  >
                    Eliminar
                  </button>
                </div>
              </div>

              {openId === m.id && (
                <div className="mg-temas">
                  <div className="mg-temas__head">
                    <h4>Temas de este módulo</h4>
                    <button
                      type="button"
                      className="mg-btn mg-btn--small mg-btn--primary"
                      onClick={() =>
                        setDialog({ kind: "tema", modulo: m, item: null })
                      }
                    >
                      + Nuevo tema
                    </button>
                  </div>

                  {temasLoading ? (
                    <p className="mg-empty" aria-busy="true">
                      Cargando temas...
                    </p>
                  ) : temas.length === 0 ? (
                    <p className="mg-empty">Este módulo aún no tiene temas.</p>
                  ) : (
                    temas.map((t) => (
                      <div key={t.id} className="mg-tema">
                        <span className="mg-tema__order">{t.orden}</span>
                        <div>
                          <strong>{t.nombre}</strong> <Badge estado={t.estado} />
                          <p>{t.descripcion}</p>
                        </div>
                        <div className="mg-actions">
                          <select
                            className="mg-select"
                            aria-label={`Estado de ${t.nombre}`}
                            value={t.estado}
                            onChange={(e) =>
                              changeTemaEstado(
                                t,
                                e.target.value as EstadoContenido
                              )
                            }
                          >
                            {ESTADOS.map((s) => (
                              <option key={s} value={s}>
                                {label(s)}
                              </option>
                            ))}
                          </select>
                          <button
                            type="button"
                            className="mg-btn mg-btn--small"
                            onClick={() =>
                              setDialog({ kind: "tema", modulo: m, item: t })
                            }
                          >
                            Editar
                          </button>
                          <button
                            type="button"
                            className="mg-btn mg-btn--small mg-btn--danger"
                            onClick={() =>
                              setConfirm({
                                kind: "tema",
                                id: t.id,
                                nombre: t.nombre,
                              })
                            }
                          >
                            Eliminar
                          </button>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              )}
            </li>
          ))}
        </ul>
      )}

      {dialog?.kind === "modulo" && (
        <ContenidoForm
          key={dialog.item?.id ?? "nuevo-modulo"}
          title={dialog.item ? "Editar módulo" : "Nuevo módulo"}
          submitLabel={dialog.item ? "Guardar cambios" : "Crear módulo"}
          initial={
            dialog.item
              ? {
                  nombre: dialog.item.nombre,
                  descripcion: dialog.item.descripcion,
                  orden: dialog.item.orden,
                  estado: dialog.item.estado,
                }
              : { nombre: "", descripcion: "", orden: nextModuloOrden, estado: "BORRADOR" }
          }
          onSubmit={saveModulo}
          onClose={() => setDialog(null)}
        />
      )}

      {dialog?.kind === "tema" && (
        <ContenidoForm
          key={dialog.item?.id ?? "nuevo-tema"}
          title={dialog.item ? "Editar tema" : "Nuevo tema"}
          submitLabel={dialog.item ? "Guardar cambios" : "Crear tema"}
          initial={
            dialog.item
              ? {
                  nombre: dialog.item.nombre,
                  descripcion: dialog.item.descripcion,
                  orden: dialog.item.orden,
                  estado: dialog.item.estado,
                }
              : { nombre: "", descripcion: "", orden: nextTemaOrden, estado: "BORRADOR" }
          }
          onSubmit={saveTema}
          onClose={() => setDialog(null)}
        />
      )}

      {confirm && (
        <div
          className="mg-overlay"
          onMouseDown={(event) => {
            if (event.target === event.currentTarget && !deleting) setConfirm(null);
          }}
        >
          <div className="mg-dialog" role="alertdialog" aria-modal="true">
            <h2>¿Eliminar {confirm.kind === "modulo" ? "módulo" : "tema"}?</h2>
            <p>
              Vas a eliminar “{confirm.nombre}”. Esta acción no se puede
              deshacer.
            </p>
            <div className="mg-dialog__actions">
              <button
                type="button"
                className="mg-btn"
                onClick={() => setConfirm(null)}
                disabled={deleting}
              >
                Cancelar
              </button>
              <button
                type="button"
                className="mg-btn mg-btn--danger"
                onClick={runDelete}
                disabled={deleting}
              >
                {deleting ? "Eliminando..." : "Sí, eliminar"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}