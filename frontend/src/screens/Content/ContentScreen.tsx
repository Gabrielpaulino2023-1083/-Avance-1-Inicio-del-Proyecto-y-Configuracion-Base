import { useEffect, useState } from "react";
import ModuleList from "../../features/content/ModuleList";
import ExercisePanel from "../../features/content/ExercisePanel";
import { getContent, type ContentData } from "../../services/contentService";
import "../../features/dashboard/dashboard.css";
import "../../features/progress/progress.css";
import "../../features/content/content.css";

export default function ContentScreen() {
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
          Continúa donde lo dejaste. Contenido de ejemplo mientras se conecta
          el backend.
        </p>
      </header>

      <div className="content-layout">
        <ModuleList courseName={content.courseName} modules={content.modules} />
        <ExercisePanel exercise={content.exercise} />
      </div>
    </div>
  );
}