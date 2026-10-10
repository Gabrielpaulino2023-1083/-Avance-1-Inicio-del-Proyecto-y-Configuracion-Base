import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { useAuth } from "../../context/authContext";

const links = [
  { to: "/", label: "Dashboard" },
  { to: "/contenido", label: "Contenido" },
  { to: "/resultados", label: "Resultados" },
  { to: "/progreso", label: "Progreso" },
];

export default function AppLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  function handleLogout() {
    logout();
    navigate("/login", { replace: true });
  }

  return (
    <div className="app-shell">
      <nav className="app-nav">
        <span className="app-nav__brand">Aprendizaje Adaptativo</span>
        <ul className="app-nav__links">
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
        <div className="app-nav__user">
          {user ? (
            <>
              <span className="app-nav__name">{user.nombre}</span>
              <button
                type="button"
                className="app-nav__logout"
                onClick={handleLogout}
              >
                Cerrar sesión
              </button>
            </>
          ) : (
            <NavLink to="/login" className="app-nav__logout">
              Iniciar sesión
            </NavLink>
          )}
        </div>
      </nav>
      <main className="app-content">
        <Outlet />
      </main>
    </div>
  );
}