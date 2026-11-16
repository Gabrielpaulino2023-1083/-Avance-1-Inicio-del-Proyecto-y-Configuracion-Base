# Frontend — Motor de Aprendizaje Adaptativo

Esta carpeta contiene la interfaz web del proyecto, construida con React y
TypeScript. El estudiante crea su cuenta, inicia sesión, ve su panel, resuelve
actividades calificadas por el servidor y recibe recomendaciones del motor
adaptativo. El administrador gestiona los cursos y, junto con el docente, el
contenido (módulos y temas).

## Pantallas y roles

Cada pantalla vive en `src/screens/` y su lógica en `src/features/`. Las
pantallas internas exigen sesión; sin ella se redirige al login. Cada rol ve
un menú distinto.

| Ruta | Pantalla | Quién la ve |
|---|---|---|
| `/login`, `/registro` | Inicio de sesión y creación de cuenta de estudiante | Público |
| `/` | Dashboard del estudiante: métricas, análisis del motor y actividad reciente | Estudiante |
| `/` | Panel de inicio con accesos rápidos | Docente y administrador |
| `/contenido` | Curso, módulos, temas y actividades; cuestionarios con calificación del servidor y recomendación del motor | Estudiante |
| `/resultados` | Historial de actividades calificadas | Estudiante |
| `/progreso` | Horas de los últimos 7 días, dominio por tema y recomendación | Estudiante |
| `/gestion` | Gestión de contenido: CRUD de módulos y temas | Docente y administrador |
| `/cursos` | Gestión de cursos: listar, crear, editar, activar y archivar | Administrador |

Un estudiante que entre a `/gestion` o `/cursos` es devuelto al inicio.

## Flujos principales

### Gestión de contenido (módulos y temas)

Trabaja con los campos de las tablas `modulos` y `temas`: nombre, descripción,
orden y estado (BORRADOR, PUBLICADO o ARCHIVADO).

- **Curso:** siempre se envía el curso elegido. El desplegable sale de
  `GET /api/cursos-administrables`: el administrador ve todos los cursos y el
  docente solo aquellos donde es editor. Si el docente no es editor del curso
  elegido, la pantalla queda en solo lectura. Sin curso elegido no se carga
  nada ni se puede crear un módulo.
- **Listar, crear y editar** con validación (nombre y descripción obligatorios,
  orden entero mayor que 0).
- **Cambiar estado** desde la lista, con `PATCH /estado`.
- **Eliminar** con confirmación. El backend solo permite eliminar un módulo en
  BORRADOR y sin temas; si no, responde 409 y la pantalla muestra el motivo.

### Cursos (administrador)

Lista, crea y edita cursos, y los activa o archiva. No existe eliminar: el
backend no tiene `DELETE` de cursos, archivar cumple esa función.

### Ciclo adaptativo (estudiante)

El flujo sigue las rutas `/api/mis-*`; el estudiante siempre sale del token y
nunca se envía en la URL ni en el cuerpo:

1. `GET /mis-cursos` devuelve las inscripciones (de ahí sale el `inscripcionId`).
2. `GET /mis-cursos/:cursoId/modulos`, `GET /mis-modulos/:moduloId/temas` y
   `GET /mis-inscripciones/:id/temas/:temaId/actividades` muestran el contenido
   publicado.
3. `POST .../actividades/:actividadId/intentos` inicia el intento y devuelve el
   cuestionario. El backend nunca envía cuál opción es la correcta.
4. `PUT /mis-respuestas/:respuestaId/opciones` guarda cada selección al elegirla.
5. `POST /mis-intentos/:intentoId/entrega` entrega y califica en el servidor. El
   frontend no calcula ni envía notas.
6. `POST /mis-inscripciones/:id/temas/:temaId/recomendacion` pide la
   recomendación al motor con los intentos calificados del tema. La tarjeta
   muestra acción, dificultad, texto y la evidencia que devuelve el backend:
   dominio (`mastery`), errores e intentos promedio.

Si se recarga la página a mitad de un intento, el `intentoId` guardado en
`sessionStorage` permite retomarlo con `GET /mis-intentos/:id/cuestionario` sin
gastar otra oportunidad.

Casos que se manejan:

- **Cargando:** botones deshabilitados y textos de espera mientras responde.
- **Sin intentos calificados (404):** "Sin datos suficientes todavía".
- **Intento ya abierto, límite de intentos o actividad no disponible (409):** se
  muestra el mensaje del backend.
- **Sin conexión:** "No se pudo conectar con el servidor".
- **Demasiados intentos (429):** mensaje claro para esperar.
- **Respuesta inválida o incompleta:** se muestra un error en lugar de inventar datos.
- **Sin resultados, sin recomendación o sin cursos:** mensajes de estado vacío.
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
`src/services/`, que decide entre datos simulados y datos reales. Las rutas
`/mis-*` están en `services/learningService.ts`.

## Configuración para usar el backend real

Por defecto el frontend funciona en **modo simulado**, sin backend. Para usar
la API real, crear `frontend/.env.local` (se puede copiar de `.env.example`)
con:

    VITE_USE_MOCK=false
    VITE_API_URL=http://localhost:3000/api

Reiniciar `npm run dev` después de cambiar este archivo. Para volver al modo
simulado, poner `VITE_USE_MOCK=true`.

El backend se enciende desde `backend/` con `npm start`, con PostgreSQL y las
migraciones y seeds de `database/` ya cargados (ver `backend/README.md`). Para
la recomendación del motor se necesita además el entorno `.venv` y las
variables `PYTHONUTF8=1` y `PYTHONIOENCODING=utf-8` en `backend/.env`. La
documentación interactiva de la API está en `http://localhost:3000/api/docs`.

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

En modo real, todas las pantallas leen la API. Los datos de ejemplo solo
aparecen en el modo simulado, y cada pantalla lo indica.

| Pantalla o dato | Origen | Estado |
|---|---|---|
| Login y registro | PostgreSQL, por la API | Real |
| Cursos (administrador) | `/api/cursos` | Real |
| Selector de curso (docente y administrador) | `/api/cursos-administrables` | Real |
| Gestión de módulos y temas | `/api/modulos`, `/api/temas` | Real |
| Dashboard: cursos, pendientes, nota promedio, horas, módulos y porcentaje | `GET /students/:id` | Real |
| Dashboard: variaciones semanales | `GET /students/:id/progress` | Real; sin datos para comparar se muestra "—" |
| Dashboard: tarjeta del motor | `GET /students/:id/progress` | Real (tema más débil del estudiante) |
| Dashboard: actividad reciente | `/mis-inscripciones/:id/actividad-reciente` | Real |
| Contenido: cursos, módulos, temas y actividades | `/mis-cursos`, `/mis-modulos`, `/mis-inscripciones` | Real |
| Cuestionario, respuestas y entrega | `/mis-intentos`, `/mis-respuestas` | Real (califica el servidor) |
| Recomendación tras un intento | `/mis-inscripciones/:id/temas/:temaId/recomendacion` + motor | Real |
| Resultados | `/mis-inscripciones/:id/resultados` | Real |
| Progreso: horas y dominio por tema | `/minutos` y `/resultados` | Real |

## Errores y limitaciones encontradas

- **Recomendación con "Error interno del servidor":** el endpoint enviaba una lista de interacciones vacía y el motor la rechaza. Backend y Motor lo corrigieron y ya responde.
- **Tema sin intentos:** la recomendación responde 404 y el frontend muestra "Sin datos suficientes".
- **Curso por defecto:** si no se envía `cursoId`, el backend usa el curso 1. El frontend siempre envía el curso elegido.
- **Nota promedio vacía:** un estudiante sin calificaciones recibe `null`; se muestra "—" y nunca 0.
- **Límite de intentos (429):** el login permite 10 intentos cada 15 minutos; se muestra un mensaje claro.
- **Porcentaje semanal:** la base no guarda el historial del progreso, así que el backend siempre devuelve `null` y se muestra un guion.
- **Actividades pendientes:** la API calcula la variación semanal con los intentos entregados, no con las pendientes. Por eso esa tarjeta no muestra variación.
- **Errores por evaluación:** no se guardan por actividad; la tabla de resultados muestra un guion en esa columna.
- **Dominio por tema:** `/progreso` mide actividades completadas, no dominio. La pantalla usa el promedio de las notas del tema (≥ 85 dominado, ≥ 60 en progreso, menor a 60 reforzar, los mismos umbrales del motor).
- **Intento abierto:** no existe una ruta para listar el intento en curso. Si el navegador pierde el `intentoId` guardado, iniciar la actividad responde 409 hasta que el intento venza.
- **Crear actividades y preguntas:** el backend no tiene rutas para eso; el docente no puede hacerlo desde la interfaz y el contenido de actividades se carga con seeds.
- **Material de refuerzo:** las lecciones no existen en la base de datos; la lista de refuerzo solo aparece en el modo simulado.
- **Usuarios del seed inicial sin acceso:** tienen hashes ficticios; se usan las cuentas de desarrollo de arriba.

## Evidencia (capturas)

Las capturas del flujo están en `docs/capturas/` y se tomaron con el backend real,
salvo las dos marcadas como modo simulado:

| Captura | Qué muestra |
|---|---|
| `01-cursos-lista` | Cursos del administrador |
| `02-contenido-selector` | Gestión de contenido con selector de curso |
| `03-eliminar-rechazado` | Rechazo del backend al eliminar un módulo publicado |
| `04-dashboard-real` | Dashboard del estudiante con datos reales y actividad reciente real |
| `05-cuestionario` | Cuestionario de una actividad con sus preguntas y opciones |
| `06-error-red` | Error con el backend apagado |
| `07-dashboard-tarjeta-ejemplo` | Tarjeta del dashboard etiquetada como ejemplo (modo simulado) |
| `08-flujo-recomendacion-refuerzo` | Recomendación con material de refuerzo (modo simulado) |
| `09-resultado-recomendacion` | Resultado calificado por el servidor y recomendación del motor |
| `10-progreso-real` | Progreso con horas de los últimos 7 días y dominio por tema |
| `11-gestion-docente-selector` | Gestión de contenido del docente con el selector de cursos |

## Tecnologías

React, TypeScript, Vite, React Router, react-hook-form y zod. Los estilos son
CSS propio, con tipografía Fraunces para los títulos y DM Sans para el texto.

## Cómo correrlo

    cd frontend
    npm install
    npm run dev

Esto levanta la aplicación en http://localhost:5173. El backend permite ese
origen mediante `CORS_ORIGIN`. Para comprobar que el proyecto compila:

    npm run build

## Flujos para probar

1. **Estudiante:** login → dashboard → contenido (elegir tema, iniciar una actividad, responder y entregar) → ver la nota → recomendación del motor → resultados y progreso.
2. **Administrador:** login → Cursos (crear, activar, archivar) → Gestión → elegir curso → crear módulo y tema → publicar → intentar eliminar un módulo publicado (error esperado).
3. **Docente:** login → Gestión → elegir uno de sus cursos → crear y editar módulos y temas.
4. **Error de red:** apagar el backend y recargar cualquier pantalla; debe aparecer un mensaje claro.
5. **Intento abierto:** iniciar una actividad, salir, borrar la entrada `adaptativo.intento.*` de Session Storage e iniciarla de nuevo; el backend responde 409 y se muestra el motivo.

## Observaciones técnicas

- La sesión se guarda en `localStorage` y el token dura 2 horas; al vencer, se cierra la sesión y se lleva al login.
- En modo real, las métricas (tiempo, intentos, errores) las calcula el backend a partir de los intentos calificados en la base de datos; el frontend no las envía.
- El motor adaptativo es un motor basado en reglas, no un modelo de aprendizaje automático.
- No hay pruebas automatizadas del frontend; se verificó con pruebas manuales por rol y con `npm run build`.
- Las animaciones respetan la preferencia `prefers-reduced-motion` del sistema.

## Responsable de este módulo

Yuleidy A. De Los Santos Reynoso — Frontend y estructura de pantallas