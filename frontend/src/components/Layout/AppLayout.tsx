import { NavLink, Outlet } from "react-router-dom";

const links = [
  { to: "/", label: "Dashboard" },
  { to: "/contenido", label: "Contenido" },
  { to: "/resultados", label: "Resultados" },
  { to: "/progreso", label: "Progreso" },
];

export default function AppLayout() {
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
      </nav>
      <main className="app-content">
        <Outlet />
      </main>
    </div>
  );
}