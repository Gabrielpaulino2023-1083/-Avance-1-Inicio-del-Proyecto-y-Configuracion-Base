# Frontend — Motor de Aprendizaje Adaptativo

Esta carpeta contiene la interfaz web del proyecto, construida con React y
TypeScript. El estudiante crea su cuenta, inicia sesión, ve su panel,
practica con ejercicios y recibe recomendaciones del motor adaptativo. El
administrador gestiona los cursos y, junto con el docente, el contenido
(módulos y temas).

## Pantallas y roles

Cada pantalla vive en `src/screens/` y su lógica en `src/features/`. Las
pantallas internas exigen sesión; sin ella se redirige al login. Cada rol ve
un menú distinto.

| Ruta | Pantalla | Quién la ve |
|---|---|---|
| `/login`, `/registro` | Inicio de sesión y creación de cuenta de estudiante | Público |
| `/` | Dashboard del estudiante: métricas, análisis del motor y actividad reciente | Estudiante |
| `/` | Panel de inicio con accesos rápidos | Docente y administrador |
| `/contenido` | Módulos del curso y ejercicio interactivo; pide recomendación al motor | Estudiante |
| `/resultados` | Historial de evaluaciones | Estudiante |
| `/progreso` | Horas de estudio, dominio por tema y recomendación | Estudiante |
| `/gestion` | Gestión de contenido: CRUD de módulos y temas | Docente y administrador |
| `/cursos` | Gestión de cursos: listar, crear, editar, activar y archivar | Administrador |

Un estudiante que entre a `/gestion` o `/cursos` es devuelto al inicio.

## Flujos principales

### Gestión de contenido (módulos y temas)

Trabaja con los campos de las tablas `modulos` y `temas`: nombre, descripción,
orden y estado (BORRADOR, PUBLICADO o ARCHIVADO).

- **Curso:** siempre se envía el curso elegido. El administrador lo elige en
  un desplegable con los cursos de la API. El docente escribe el ID del curso
  que edita (provisional, mientras no exista la ruta "mis cursos"). Sin curso
  elegido no se carga nada ni se puede crear un módulo.
- **Listar, crear y editar** con validación (nombre y descripción obligatorios,
  orden entero mayor que 0).
- **Cambiar estado** desde la lista, con `PATCH /estado`.
- **Eliminar** con confirmación. El backend solo permite eliminar un módulo en
  BORRADOR y sin temas; si no, responde 409 y la pantalla muestra el motivo.

### Cursos (administrador)

Lista, crea y edita cursos, y los activa o archiva. No existe eliminar: el
backend no tiene `DELETE` de cursos, archivar cumple esa función.

### Ciclo adaptativo (estudiante)

Al resolver el ejercicio de `/contenido`, el botón "Ver recomendación del
motor" llama a `POST /api/students/:id/recommendation` con el tema. La tarjeta
muestra acción, dificultad, texto y la evidencia que devuelve el backend:
dominio del tema (`mastery`), errores y intentos promedio. Nada de eso se
calcula en el frontend en modo real. Después de la tarjeta aparece una lista de
material de refuerzo (si la acción es reforzar) o de contenido pendiente.

Casos que se manejan:

- **Cargando:** el botón queda deshabilitado mientras responde.
- **Sin intentos calificados (404):** "Sin datos suficientes todavía".
- **Sin conexión:** "No se pudo conectar con el servidor".
- **Demasiados intentos (429):** mensaje claro para esperar.
- **Respuesta inválida o incompleta:** se muestra un error en lugar de inventar datos.
- **Sesión vencida (401):** se cierra la sesión y se lleva al login.

## Cómo está organizado

    src/
    ├── components/   Barra de navegación y ruta protegida
    ├── context/      Sesión del usuario (AuthProvider)
    ├── features/     Componentes de cada pantalla (auth, dashboard, content, progress, results, manage, courses)
    ├── screens/      Una carpeta por pantalla
    ├── services/     Comunicación con el backend y datos simulados
    ├── types/        Tipos de TypeScript compartidos
    └── theme-dark.css  Tema visual oscuro de toda la plataforma

Las pantallas nunca llaman al backend directamente: todo pasa por
`src/services/`, que decide entre datos simulados y datos reales.

## Configuración para usar el backend real

Por defecto el frontend funciona en **modo simulado**, sin backend. Para usar
la API real, crear `frontend/.env.local` (se puede copiar de `.env.example`)
con:

    VITE_USE_MOCK=false
    VITE_API_URL=http://localhost:3000/api

Reiniciar `npm run dev` después de cambiar este archivo. Para volver al modo
simulado, poner `VITE_USE_MOCK=true`.

El backend se enciende desde `backend/` con `npm start`, con PostgreSQL y las
migraciones y seeds de `database/` ya cargados (ver `backend/README.md`).

Cuentas de desarrollo en modo real (seeds del repositorio):

| Rol | Correo | Contraseña |
|---|---|---|
| Administrador | `administrador.demo@example.com` | `AdminDemo-2026!` |
| Docente | `docente.demo@example.com` | `DocenteDemo-2026!` |
| Estudiante | `estudiante.demo@example.com` | `DemoEquipo-2026!` |

Cuentas en modo simulado:

| Rol | Correo | Contraseña |
|---|---|---|
| Estudiante | `estudiante@example.com` | `estudiante123` |
| Docente | `docente@example.com` | `docente123` |
| Administrador | `administrador@example.com` | `admin12345` |

## Qué es real y qué sigue simulado (modo real)

Cada pantalla indica en pantalla cuál es su caso.

| Pantalla o dato | Origen | Estado |
|---|---|---|
| Login y registro | PostgreSQL, por la API | Real |
| Cursos (administrador) | `/api/cursos` | Real |
| Gestión de módulos y temas | `/api/modulos`, `/api/temas` | Real (el docente aún escribe el ID del curso) |
| Recomendación del ejercicio (tarjeta y evidencia) | `POST /students/:id/recommendation` + motor | Real |
| Dashboard: cursos activos, actividades pendientes, nota promedio, horas de estudio | `GET /students/:id` | Real (la nota puede venir vacía y se muestra "—") |
| Dashboard: porcentaje, módulos, variaciones, tarjeta de recomendación, actividad reciente | `GET /students/:id/progress` y frontend | Simulado, etiquetado "Datos de ejemplo" |
| Contenido del estudiante: módulos, lecciones y ejercicio | Frontend | Simulado |
| Material de refuerzo | Frontend | Simulado (las lecciones aún no se abren) |
| Resultados y Progreso | Frontend | Simulado |

## Errores y limitaciones encontradas

- **Recomendación con "Error interno del servidor":** el endpoint enviaba una lista de interacciones vacía y el motor la rechaza. Backend y Motor lo corrigieron y ya responde.
- **Tema sin intentos:** el ejercicio usa el tema "SQL JOIN", que en la base local no tiene intentos calificados; el backend responde 404 y el frontend muestra "Sin datos suficientes".
- **Curso por defecto:** si no se envía `cursoId`, el backend usa el curso 1. El frontend siempre envía el curso elegido.
- **Nota promedio vacía:** un estudiante sin calificaciones recibe `null`; se muestra "—" y nunca 0.
- **Límite de intentos (429):** el login permite 10 intentos cada 15 minutos; se muestra un mensaje claro.
- **Rutas faltantes:** no existe aún "mis cursos" para el docente ni rutas para progreso, actividad reciente y minutos reales. La base de datos ya tiene las consultas (migración 008) y falta exponerlas en la API.
- **Recomendación por nombre de tema:** el backend busca el tema por nombre y no distingue homónimos. Se propone cambiarlo a `inscripcionId` y `temaId`.
- **Usuarios del seed inicial sin acceso:** tienen hashes ficticios; se usan las cuentas de desarrollo de arriba.

## Evidencia (capturas)

Las capturas del flujo están en `docs/capturas/` y se tomaron con el backend real,
salvo la última, que usa el modo simulado:

| Captura | Qué muestra |
|---|---|
| `01-cursos-lista` | Cursos del administrador |
| `02-contenido-selector` | Contenido con selector de curso |
| `03-eliminar-rechazado` | Rechazo del backend al eliminar un módulo publicado |
| `04-dashboard-real` | Dashboard del estudiante con datos reales |
| `05-sin-datos` | Recomendación sin intentos calificados |
| `06-error-red` | Error con el backend apagado |
| `07-dashboard-tarjeta-ejemplo` | Tarjeta del dashboard etiquetada como ejemplo |
| `08-flujo-recomendacion-refuerzo` | Recomendación con material de refuerzo (modo simulado) |

## Tecnologías

React, TypeScript, Vite, React Router y react-hook-form. Los estilos son CSS
propio, con tipografía Fraunces para los títulos y DM Sans para el texto.

## Cómo correrlo

    cd frontend
    npm install
    npm run dev

Esto levanta la aplicación en http://localhost:5173. El backend permite ese
origen mediante `CORS_ORIGIN`. Para comprobar que el proyecto compila:

    npm run build

## Flujos para probar

1. **Estudiante:** login → dashboard → contenido (ejercicio con errores y pista) → recomendación del motor → material de refuerzo.
2. **Administrador:** login → Cursos (crear, activar, archivar) → Contenido → elegir curso → crear módulo y tema → publicar → intentar eliminar un módulo publicado (error esperado).
3. **Docente:** login → Contenido → escribir el ID del curso → crear y editar módulos y temas.
4. **Error de red:** apagar el backend e intentar iniciar sesión; debe aparecer un mensaje claro.

## Observaciones técnicas

- La sesión se guarda en `localStorage` y el token dura 2 horas; al vencer, se cierra la sesión y se lleva al login.
- Los ejercicios todavía no guardan sus métricas (tiempo, intentos, errores) en el backend; en modo real el motor usa los intentos calificados que ya están en la base de datos.
- El motor adaptativo es un motor basado en reglas, no un modelo de aprendizaje automático.
- Las animaciones respetan la preferencia `prefers-reduced-motion` del sistema.

## Responsable de este módulo

Yuleidy A. De Los Santos Reynoso — Frontend y estructura de pantallas