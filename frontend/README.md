# Frontend — Motor de Aprendizaje Adaptativo

Esta carpeta contiene la interfaz web del proyecto, construida con React
y TypeScript. Es la parte con la que el usuario interactúa directamente:
el estudiante crea su cuenta, inicia sesión, ve su panel de progreso,
practica con ejercicios, revisa sus resultados y recibe recomendaciones
del motor adaptativo; el docente administra los módulos y temas del curso.

## Qué contiene

Cada pantalla vive en `src/screens/` y la lógica de cada una en
`src/features/`. La navegación se maneja con React Router, y las
pantallas internas están protegidas: sin sesión iniciada se redirige
al login.

- `/login` — inicio de sesión
- `/registro` — creación de cuenta de estudiante
- `/` — dashboard: progreso general, métricas, análisis del motor adaptativo y actividad reciente
- `/contenido` — módulos del curso y un ejercicio interactivo que mide tiempo, intentos y errores; al terminarlo, pide una recomendación al motor adaptativo
- `/resultados` — historial de evaluaciones, evolución de las notas y qué reforzar
- `/progreso` — horas de estudio, dominio por tema y recomendación del motor
- `/gestion` — gestión de contenido (solo DOCENTE y ADMINISTRADOR): CRUD de módulos y temas

## Módulos adicionales

### Gestión de contenido (CRUD)

Pantalla para que el docente administre el curso. Trabaja con los mismos
campos de las tablas `modulos` y `temas` de la base de datos: nombre,
descripción, orden y estado (BORRADOR, PUBLICADO o ARCHIVADO).

- **Listar:** módulos ordenados, con contadores por estado, filtro por estado y cantidad de temas.
- **Crear y editar:** formulario con validación (nombre y descripción obligatorios, orden entero mayor que 0).
- **Cambiar estado:** desde la misma lista (por ejemplo, publicar un borrador).
- **Eliminar:** con ventana de confirmación.
- **Temas:** cada módulo se expande para administrar sus temas con las mismas operaciones.

Las reglas imitan las restricciones de la base de datos: no se repite el
orden dentro del mismo curso o módulo, y no se puede eliminar un módulo
que todavía tiene temas (`ON DELETE RESTRICT`). El menú "Gestión" solo
aparece para docentes y administradores; un estudiante que entre a la
ruta es devuelto al inicio.

### Ciclo adaptativo

Al acertar el ejercicio de `/contenido`, el botón "Ver recomendación del
motor" envía el tema y la actividad del estudiante (tiempo, intentos y
errores) y muestra la recomendación con la misma tarjeta del dashboard.
Si el servicio falla, se muestra un mensaje claro y se puede reintentar.

## Cómo está organizado

    src/
    ├── components/   Barra de navegación y ruta protegida
    ├── context/      Sesión del usuario (AuthProvider)
    ├── features/     Componentes de cada pantalla (auth, dashboard, content, progress, results, manage)
    ├── screens/      Una carpeta por pantalla
    ├── services/     Comunicación con el backend y datos simulados
    ├── types/        Tipos de TypeScript compartidos
    └── theme-dark.css  Tema visual oscuro de toda la plataforma

Las pantallas nunca llaman al backend directamente: todo pasa por
`src/services/`. Eso permite cambiar entre datos simulados y datos
reales sin tocar la interfaz.

## Conexión con el backend

Endpoints que el frontend ya usa:

- `POST /api/auth/login` y `POST /api/auth/register`
- `GET /api/students/:id` (resumen del estudiante)
- `GET /api/students/:id/progress` (progreso y recomendación)
- `POST /api/students/:id/recommendation` (recomendación del motor, ejercicio)

Endpoints que el frontend ya tiene preparados pero que todavía no existen
en el backend (contrato propuesto, `src/services/curriculumService.ts`):

- `GET/POST /api/modulos`, `PUT/DELETE /api/modulos/:id`
- `GET/POST /api/modulos/:id/temas`, `PUT/DELETE /api/temas/:id`
- Permiso de escritura de contenido para DOCENTE y ADMINISTRADOR

Los campos que devuelve el backend están en español (`porcentajeCompletado`,
`notaPromedio`...). El archivo `src/services/dashboardService.ts` los
traduce al formato que usan las pantallas.

### Datos simulados y datos reales

Por defecto el frontend funciona en **modo simulado**, sin necesidad de
backend. Para usar la API real, crear un archivo `frontend/.env.local`
(se puede copiar de `.env.example`) con:

    VITE_USE_MOCK=false
    VITE_API_URL=http://localhost:3000/api

| Pantalla o dato | Origen | Estado |
|---|---|---|
| Login y registro | PostgreSQL, por la API | Real, verificado |
| Dashboard: nombre, rol y cursos activos | PostgreSQL, por la API | Real |
| Dashboard: porcentaje, módulos, pendientes, nota promedio, horas, variaciones y análisis del motor | Backend (`simulado: true`) | Simulado en el backend |
| Dashboard: actividad reciente | Frontend | Simulado |
| Contenido: módulos y ejercicio | Frontend | Simulado |
| Recomendación al terminar el ejercicio | Backend y motor adaptativo | Endpoint existente, devuelve "Error interno del servidor" (pendiente de corrección por Backend y Motor) |
| Resultados y Progreso | Frontend | Simulado |
| Gestión de contenido (CRUD de módulos y temas) | Frontend, guardado en el navegador | Simulado: faltan los endpoints del backend |

Al cambiar a datos reales, solo se modifica el servicio correspondiente
en `src/services/`; las pantallas no cambian.

## Evidencia con datos reales

Se probó el frontend contra el backend y PostgreSQL locales
(`VITE_USE_MOCK=false`):

- **Crear:** el registro desde `/registro` guarda el usuario en la tabla `usuarios` con su rol `ESTUDIANTE` y la contraseña cifrada con bcrypt.
- **Consultar:** el login devuelve el token y los datos del usuario, y el dashboard muestra su nombre, su rol y sus cursos activos desde la base de datos.
- **Pendiente:** el resto de datos del dashboard sigue simulado en el backend, y la recomendación del ejercicio falla por un error interno ya conocido por el equipo de Backend y Motor.

Para repetir la prueba: crear la base `motor_adaptativo` con las migraciones y
los datos de prueba de `database/`, configurar el `.env` del backend, encenderlo
con `npm start` y poner `VITE_USE_MOCK=false` en `frontend/.env.local`.

## Tecnologías

React, TypeScript, Vite, React Router, react-hook-form y zod (formularios
y validación). Los estilos son CSS propio, con tipografía Fraunces para
los títulos y DM Sans para el texto.

## Cómo correrlo

    cd frontend
    npm install
    npm run dev

Esto levanta la aplicación en http://localhost:5173. El backend permite
ese origen mediante `CORS_ORIGIN`.

Usuarios de prueba en modo simulado:

| Rol | Correo | Contraseña |
|---|---|---|
| Estudiante | `estudiante@example.com` | `estudiante123` |
| Docente | `docente@example.com` | `docente123` |

Para comprobar que el proyecto compila:

    npm run build

## Flujos para probar

1. **Estudiante:** registro → login → dashboard → contenido (ejercicio con errores y pista) → recomendación del motor → resultados y progreso.
2. **Docente:** login → Gestión → crear módulo → editar → cambiar estado → agregar temas → intentar eliminar un módulo con temas (error esperado) → eliminar uno sin temas.

## Problemas resueltos

- **Contrato entre frontend y backend:** el frontend esperaba `/students/me/summary` con campos en inglés; el backend expone `/students/:id` con campos en español. Se resolvió con un adaptador en `dashboardService.ts`.
- **Puerto y CORS:** el backend pasó del puerto 4000 al 3000 y habilita el origen del frontend con `CORS_ORIGIN`, por lo que ya no hace falta un proxy.
- **Usuarios del seed sin acceso:** los usuarios de ejemplo tienen hashes ficticios y no pueden iniciar sesión; se usa el registro (`/registro`) para crear usuarios reales.
- **Sesión vencida:** ante un 401 la aplicación cierra la sesión y redirige al login.
- **Rutas protegidas:** las pantallas internas exigen sesión, y la gestión de contenido exige rol DOCENTE o ADMINISTRADOR.
- **Desarrollo sin backend:** capa de servicios con modo simulado para trabajar y probar sin depender de otros módulos.
- **Estilos:** conflictos de cascada resueltos con un único archivo de tema cargado al final; escala y jerarquía visual corregidas en pantallas anchas.
- **Error detectado en la integración del motor:** el endpoint de recomendación envía `interactions: []` y el motor rechaza listas vacías; se reportó al equipo de backend y motor.

## Observaciones técnicas

- La sesión se guarda en `localStorage` y el token del backend dura 2 horas;
  cuando vence, la aplicación cierra la sesión y lleva al login.
- Los ejercicios todavía no guardan sus métricas (tiempo, intentos, errores)
  en el backend porque no existe el endpoint para registrarlas; se usan
  solo para pedir la recomendación.
- El CRUD de módulos y temas guarda en el navegador mientras no existan
  los endpoints; al cambiar a datos reales no se modifica ninguna pantalla.
- El motor adaptativo es un motor basado en reglas, no un modelo de aprendizaje automático.
- Las animaciones respetan la preferencia `prefers-reduced-motion` del sistema.
- La recomendación del motor se probó con el backend real y respondió "Error interno del servidor"; el frontend lo muestra con un mensaje claro y permite reintentar. Mientras se corrige, el modo simulado muestra el comportamiento esperado.

## Responsable de este módulo

Yuleidy A. De Los Santos Reynoso — Frontend y estructura de pantallas