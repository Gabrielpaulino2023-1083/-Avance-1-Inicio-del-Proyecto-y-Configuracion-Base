import { useEffect, useState } from "react";
import { Navigate } from "react-router-dom";
import { useAuth } from "../../context/authContext";
import { ApiError } from "../../services/http";
import {
  USER_ADMIN_ENABLED,
  changeUsuarioActivo,
  changeUsuarioRol,
  listUsuarios,
} from "../../services/userAdminService";
import {
  ROLES_USUARIO,
  type RolUsuario,
  type UsuarioAdmin,
} from "../../types/userAdmin";
import "../../features/dashboard/dashboard.css";
import "../../features/progress/progress.css";
import "../../features/manage/manage.css";

type Filter = "TODOS" | RolUsuario;
type Notice = { ok: boolean; text: string };

const ROL_LABEL: Record<RolUsuario, string> = {
  ESTUDIANTE: "Estudiante",
  DOCENTE: "Docente",
  ADMINISTRADOR: "Administrador",
};

export default function UsersScreen() {
  const { user, token, logout } = useAuth();
  const [usuarios, setUsuarios] = useState<UsuarioAdmin[] | null>(null);
  const [filter, setFilter] = useState<Filter>("TODOS");
  const [deactivating, setDeactivating] = useState<UsuarioAdmin | null>(null);
  const [busyId, setBusyId] = useState<number | null>(null);
  const [notice, setNotice] = useState<Notice | null>(null);

  const actorId = user?.id ?? 0;
  const allowed = USER_ADMIN_ENABLED && user?.rol === "ADMINISTRADOR";

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
    if (!allowed) return;
    let active = true;
    listUsuarios(token)
      .then((data) => {
        if (active) setUsuarios(data);
      })
      .catch((error) => {
        if (!active) return;
        setUsuarios([]);
        fail(error);
      });
    return () => {
      active = false;
    };
    // eslint-disable-next-line
  }, [token, allowed]);

  // El aviso se esconde solo.
  useEffect(() => {
    if (!notice) return;
    const timer = setTimeout(() => setNotice(null), 4500);
    return () => clearTimeout(timer);
  }, [notice]);

  // Solo el ADMINISTRADOR entra, y solo si la función está habilitada.
  if (!allowed) {
    return <Navigate to="/" replace />;
  }

  async function refresh() {
    setUsuarios(await listUsuarios(token));
  }

  async function changeRol(u: UsuarioAdmin, rol: RolUsuario) {
    if (rol === u.rol) return;
    setBusyId(u.id);
    try {
      await changeUsuarioRol(token, u.id, rol, actorId);
      setNotice({ ok: true, text: `Rol de ${u.nombre} cambiado a ${ROL_LABEL[rol]}.` });
    } catch (error) {
      fail(error);
    } finally {
      await refresh().catch(fail); // vuelve al valor real si hubo un rechazo
      setBusyId(null);
    }
  }

  async function setActivo(u: UsuarioAdmin, activo: boolean) {
    setBusyId(u.id);
    try {
      await changeUsuarioActivo(token, u.id, activo, actorId);
      setNotice({
        ok: true,
        text: activo ? `${u.nombre} fue activado.` : `${u.nombre} fue desactivado.`,
      });
    } catch (error) {
      fail(error);
    } finally {
      await refresh().catch(fail);
      setBusyId(null);
      setDeactivating(null);
    }
  }

  if (!usuarios) {
    return (
      <div className="dash-state" aria-busy="true">
        Cargando usuarios...
      </div>
    );
  }

  const visible =
    filter === "TODOS" ? usuarios : usuarios.filter((u) => u.rol === filter);

  return (
    <div className="dash">
      <header className="page-head">
        <h1>Gestión de usuarios</h1>
        <p>
          Cambia el rol de un usuario o desactiva su cuenta. Siempre debe quedar
          al menos un administrador activo, y nadie puede cambiar su propio rol
          ni desactivarse a sí mismo.
        </p>
      </header>

      <ul className="mg-stats">
        <li className="mg-stat">
          <span>Usuarios</span>
          <strong>{usuarios.length}</strong>
        </li>
        <li className="mg-stat">
          <span>Activos</span>
          <strong>{usuarios.filter((u) => u.activo).length}</strong>
        </li>
        <li className="mg-stat">
          <span>Inactivos</span>
          <strong>{usuarios.filter((u) => !u.activo).length}</strong>
        </li>
        <li className="mg-stat">
          <span>Administradores</span>
          <strong>
            {usuarios.filter((u) => u.rol === "ADMINISTRADOR").length}
          </strong>
        </li>
      </ul>

      <div className="mg-toolbar">
        <div className="mg-filters" role="group" aria-label="Filtrar por rol">
          {(["TODOS", ...ROLES_USUARIO] as Filter[]).map((f) => (
            <button
              key={f}
              type="button"
              className="mg-chip"
              aria-pressed={filter === f}
              onClick={() => setFilter(f)}
            >
              {f === "TODOS" ? "Todos" : ROL_LABEL[f]}
            </button>
          ))}
        </div>
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
        <p className="mg-empty">No hay usuarios con este rol.</p>
      ) : (
        <ul className="mg-list">
          {visible.map((u) => {
            const itsMe = u.id === actorId;
            const busy = busyId === u.id;
            return (
              <li key={u.id} className="mg-item">
                <div className="mg-item__row">
                  <span className="mg-order" aria-label={`Usuario ${u.id}`}>
                    {u.id}
                  </span>

                  <div className="mg-item__main">
                    <h3>
                      {u.nombre} {u.apellido}{" "}
                      <span
                        className={`mg-badge mg-badge--${u.activo ? "activo" : "archivado"}`}
                      >
                        {u.activo ? "Activo" : "Inactivo"}
                      </span>
                      {itsMe && " (tú)"}
                    </h3>
                    <div className="mg-item__meta">{u.email}</div>
                  </div>

                  <div className="mg-actions">
                    <select
                      className="mg-select"
                      aria-label={`Rol de ${u.nombre}`}
                      value={u.rol}
                      disabled={busy || itsMe}
                      onChange={(e) => changeRol(u, e.target.value as RolUsuario)}
                    >
                      {ROLES_USUARIO.map((r) => (
                        <option key={r} value={r}>
                          {ROL_LABEL[r]}
                        </option>
                      ))}
                    </select>
                    {u.activo ? (
                      <button
                        type="button"
                        className="mg-btn mg-btn--small mg-btn--danger"
                        disabled={busy || itsMe}
                        onClick={() => setDeactivating(u)}
                      >
                        Desactivar
                      </button>
                    ) : (
                      <button
                        type="button"
                        className="mg-btn mg-btn--small mg-btn--primary"
                        disabled={busy}
                        onClick={() => setActivo(u, true)}
                      >
                        Activar
                      </button>
                    )}
                  </div>
                </div>
              </li>
            );
          })}
        </ul>
      )}

      {deactivating && (
        <div
          className="mg-overlay"
          onMouseDown={(event) => {
            if (event.target === event.currentTarget && busyId === null) {
              setDeactivating(null);
            }
          }}
        >
          <div className="mg-dialog" role="alertdialog" aria-modal="true">
            <h2>¿Desactivar usuario?</h2>
            <p>
              Vas a desactivar la cuenta de {deactivating.nombre}{" "}
              {deactivating.apellido}. No podrá iniciar sesión hasta que la
              actives de nuevo. Sus datos se conservan.
            </p>
            <div className="mg-dialog__actions">
              <button
                type="button"
                className="mg-btn"
                onClick={() => setDeactivating(null)}
                disabled={busyId !== null}
              >
                Cancelar
              </button>
              <button
                type="button"
                className="mg-btn mg-btn--danger"
                onClick={() => setActivo(deactivating, false)}
                disabled={busyId !== null}
              >
                {busyId !== null ? "Desactivando..." : "Sí, desactivar"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}