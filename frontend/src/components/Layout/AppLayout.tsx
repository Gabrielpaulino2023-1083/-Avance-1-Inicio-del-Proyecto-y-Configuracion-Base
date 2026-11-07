import { NavLink, Outlet, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../../context/authContext";
import { CapIcon, LogoutIcon } from "../../features/auth/icons";
import "./nav.css";

const links = [
  { to: "/", label: "Dashboard" },
  { to: "/contenido", label: "Contenido" },
  { to: "/resultados", label: "Resultados" },
  { to: "/progreso", label: "Progreso" },
];

const ROLE_LABEL = {
  ESTUDIANTE: "Estudiante",
  DOCENTE: "Docente",
  ADMINISTRADOR: "Administrador",
} as const;

export default function AppLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
    const location = useLocation();

  function handleLogout() {
    logout();
    navigate("/login", { replace: true });
  }

  const initials = user
    ? `${user.nombre.charAt(0)}${user.apellido.charAt(0)}`.toUpperCase()
    : "";

  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="topbar__inner">
          <NavLink to="/" className="topbar__brand">
            <span className="topbar__mark">
              <CapIcon />
            </span>
            <span>
              Aprendizaje <em>Adaptativo</em>
            </span>
          </NavLink>

          <nav className="topbar__nav" aria-label="Principal">
            <ul>
              {links.map((link) => (
                <li key={link.to}>
                  <NavLink
                    to={link.to}
                    end={link.to === "/"}
                    className={({ isActive }) => (isActive ? "active" : undefined)}
                  >
                    {link.label}
                  </NavLink>
                </li>
              ))}
            </ul>
          </nav>

          <div className="topbar__user">
            {user ? (
              <>
                <span className="topbar__avatar" aria-hidden="true">
                  {initials}
                </span>
                <span className="topbar__who">
                  <strong>{user.nombre}</strong>
                  <small>{ROLE_LABEL[user.rol]}</small>
                </span>
                <button
                  type="button"
                  className="topbar__logout"
                  onClick={handleLogout}
                  aria-label="Cerrar sesión"
                  title="Cerrar sesión"
                >
                  <LogoutIcon />
                </button>
              </>
            ) : (
              <NavLink to="/login" className="topbar__login">
                Iniciar sesión
              </NavLink>
            )}
          </div>
        </div>
      </header>

        <main className="app-content">
        <div key={location.pathname} className="page">
          <Outlet />
        </div>
      </main>
    </div>
  );
}