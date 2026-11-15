import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../../context/authContext";
import { listCursos } from "../../services/courseService";
import { listModulos } from "../../services/curriculumService";
import "./dashboard.css";
import "../progress/progress.css";
import "../manage/manage.css";

interface Stat {
  label: string;
  value: number;
}

interface Shortcut {
  to: string;
  title: string;
  text: string;
}

// Panel de inicio para ADMINISTRADOR y DOCENTE (el estudiante tiene el suyo).
export default function StaffDashboard() {
  const { user, token } = useAuth();
  const isAdmin = user?.rol === "ADMINISTRADOR";
  const [stats, setStats] = useState<Stat[] | null>(null);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    let active = true;

    async function load(): Promise<Stat[]> {
      if (isAdmin) {
        const cursos = await listCursos(token);
        const count = (estado: string) =>
          cursos.filter((c) => c.estado === estado).length;
        return [
          { label: "Cursos", value: cursos.length },
          { label: "Activos", value: count("ACTIVO") },
          { label: "En borrador", value: count("BORRADOR") },
          { label: "Archivados", value: count("ARCHIVADO") },
        ];
      }
      const modulos = await listModulos(token);
      const count = (estado: string) =>
        modulos.filter((m) => m.estado === estado).length;
      return [
        { label: "Módulos", value: modulos.length },
        { label: "Publicados", value: count("PUBLICADO") },
        { label: "En borrador", value: count("BORRADOR") },
        {
          label: "Temas",
          value: modulos.reduce((sum, m) => sum + m.totalTemas, 0),
        },
      ];
    }

    load()
      .then((data) => {
        if (active) setStats(data);
      })
      .catch(() => {
        if (active) setFailed(true);
      });

    return () => {
      active = false;
    };
  }, [isAdmin, token]);

  const shortcuts: Shortcut[] = [
    ...(isAdmin
      ? [
          {
            to: "/cursos",
            title: "Gestión de cursos",
            text: "Crea, edita, activa y archiva los cursos de la plataforma.",
          },
        ]
      : []),
    {
      to: "/gestion",
      title: "Módulos y temas",
      text: "Organiza el contenido de cada curso y controla qué se publica.",
    },
  ];

  return (
    <div className="dash">
      <header className="page-head">
        <h1>{isAdmin ? "Panel de administración" : "Panel docente"}</h1>
        <p>
          Bienvenido, {user?.nombre}.{" "}
          {isAdmin
            ? "Aquí administras los cursos y el contenido de la plataforma."
            : "Aquí administras el contenido de los cursos."}
        </p>
      </header>

      {stats && (
        <ul className="mg-stats">
          {stats.map((s) => (
            <li key={s.label} className="mg-stat">
              <span>{s.label}</span>
              <strong>{s.value}</strong>
            </li>
          ))}
        </ul>
      )}

      {!stats && !failed && (
        <div className="dash-state" aria-busy="true">
          Cargando información...
        </div>
      )}

      {failed && (
        <p className="mg-notice mg-notice--error" role="status">
          No se pudieron cargar las estadísticas en este momento.
        </p>
      )}

      <ul className="sf-actions">
        {shortcuts.map((s) => (
          <li key={s.to}>
            <Link to={s.to} className="sf-card">
              <strong>{s.title}</strong>
              <span>{s.text}</span>
              <em>Abrir →</em>
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}