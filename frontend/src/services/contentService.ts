// Contenido del curso y ejercicio actual. DATOS DE EJEMPLO:
// el backend todavía no tiene tablas de contenidos ni de interacciones.
// Cuando existan, solo se cambia este archivo.

export type LessonStatus = "done" | "current" | "pending";

export interface Lesson {
  id: number;
  title: string;
  kind: "lesson" | "exercise";
  minutes: number;
  status: LessonStatus;
}

export interface CourseModule {
  id: number;
  title: string;
  lessons: Lesson[];
}

export interface Exercise {
  id: number;
  topic: string;
  question: string;
  options: string[];
  correctIndex: number;
  hint: string;
  explanation: string;
}

export interface ContentData {
  courseName: string;
  modules: CourseModule[];
  exercise: Exercise;
}

const MOCK_CONTENT: ContentData = {
  courseName: "Bases de Datos I",
  modules: [
    {
      id: 1,
      title: "Fundamentos de consultas",
      lessons: [
        { id: 1, title: "Consultas con SELECT y WHERE", kind: "lesson", minutes: 15, status: "done" },
        { id: 2, title: "Filtrado y ordenamiento", kind: "lesson", minutes: 20, status: "done" },
        { id: 3, title: "Práctica de consultas", kind: "exercise", minutes: 10, status: "done" },
      ],
    },
    {
      id: 2,
      title: "Relaciones entre tablas",
      lessons: [
        { id: 4, title: "Introducción a SQL JOIN", kind: "lesson", minutes: 20, status: "done" },
        { id: 5, title: "Práctica de SQL JOIN", kind: "exercise", minutes: 15, status: "current" },
        { id: 6, title: "Tipos de JOIN avanzados", kind: "lesson", minutes: 25, status: "pending" },
      ],
    },
    {
      id: 3,
      title: "Agregación y agrupación",
      lessons: [
        { id: 7, title: "COUNT, SUM y AVG", kind: "lesson", minutes: 20, status: "pending" },
        { id: 8, title: "GROUP BY y HAVING", kind: "exercise", minutes: 20, status: "pending" },
      ],
    },
  ],
  exercise: {
    id: 5,
    topic: "SQL JOIN",
    question:
      "¿Qué tipo de JOIN devuelve solo las filas que tienen coincidencia en ambas tablas?",
    options: ["LEFT JOIN", "INNER JOIN", "FULL OUTER JOIN", "CROSS JOIN"],
    correctIndex: 1,
    hint: "Piensa en qué filas se conservan cuando una de las dos tablas no tiene pareja.",
    explanation:
      "INNER JOIN solo devuelve las filas cuya condición se cumple en las dos tablas. LEFT JOIN conserva además todas las filas de la tabla izquierda, aunque no tengan pareja.",
  },
};

function wait(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function getContent(): Promise<ContentData> {
  await wait(500);
  return MOCK_CONTENT;
}