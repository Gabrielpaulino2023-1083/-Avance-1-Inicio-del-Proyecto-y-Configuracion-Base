import { useEffect, useState } from "react";
import ModuleList from "../../features/content/ModuleList";
import ExercisePanel from "../../features/content/ExercisePanel";
import RealCourse from "../../features/content/RealCourse";
import { getContent, type ContentData } from "../../services/contentService";
import "../../features/dashboard/dashboard.css";
import "../../features/progress/progress.css";
import "../../features/content/content.css";
import { USE_MOCK } from "../../services/http";

function MockContentScreen() {
  const [content, setContent] = useState<ContentData | null>(null);

  useEffect(() => {
    let active = true;
    getContent().then((data) => {
      if (active) setContent(data);
    });
    return () => {
      active = false;
    };
  }, []);

  if (!content) {
    return (
      <div className="dash-state" aria-busy="true">
        Cargando tu curso...
      </div>
    );
  }

  return (
    <div className="dash">
      <header className="page-head">
        <h1>Contenido y ejercicios</h1>
        <p>
          {USE_MOCK
            ? "Continúa donde lo dejaste. Contenido de ejemplo mientras se conecta el backend."
            : "Continúa donde lo dejaste. El contenido es de ejemplo; la recomendación del motor usa datos reales del backend."}
        </p>
      </header>

      <div className="content-layout">
        <ModuleList courseName={content.courseName} modules={content.modules} />
        <ExercisePanel exercise={content.exercise} modules={content.modules} />      </div>
    </div>
  );
}

// Con la API real se navega el contenido publicado; en modo simulado se
// mantiene la pantalla de ejemplo.
function RealContentScreen() {
  return (
    <div className="dash">
      <header className="page-head">
        <h1>Contenido y ejercicios</h1>
        <p>
          Elige un tema para ver sus actividades. El contenido viene de la
          base de datos.
        </p>
      </header>
      <RealCourse />
    </div>
  );
}

export default function ContentScreen() {
  return USE_MOCK ? <MockContentScreen /> : <RealContentScreen />;
}