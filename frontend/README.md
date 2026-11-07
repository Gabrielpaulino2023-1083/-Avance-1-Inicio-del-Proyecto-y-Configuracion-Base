# Frontend — Motor de Aprendizaje Adaptativo

Esta carpeta contiene la interfaz web del proyecto, construida con React
y TypeScript. Es la parte con la que el estudiante interactúa
directamente: crea su cuenta, inicia sesión, ve su panel de progreso,
practica con ejercicios, revisa sus resultados y consulta las
recomendaciones del motor adaptativo.

## Qué contiene

Cada pantalla vive en `src/screens/` y la lógica de cada una en
`src/features/`. La navegación se maneja con React Router, y las
pantallas internas están protegidas: sin sesión iniciada se redirige
al login.

- `/login` — inicio de sesión
- `/registro` — creación de cuenta de estudiante
- `/` — dashboard: progreso general, métricas, análisis del motor adaptativo y actividad reciente
- `/contenido` — módulos del curso y un ejercicio interactivo que mide tiempo, intentos y errores
- `/resultados` — historial de evaluaciones, evolución de las notas y qué reforzar
- `/progreso` — horas de estudio, dominio por tema y recomendación del motor

## Cómo está organizado

    src/
    ├── components/   Barra de navegación y ruta protegida
    ├── context/      Sesión del usuario (AuthProvider)
    ├── features/     Componentes de cada pantalla (auth, dashboard, content, progress, results)
    ├── screens/      Una carpeta por pantalla
    ├── services/     Comunicación con el backend y datos simulados
    ├── types/        Tipos de TypeScript compartidos
    └── theme-dark.css  Tema visual oscuro de toda la plataforma

Las pantallas nunca llaman al backend directamente: todo pasa por
`src/services/`. Eso permite cambiar entre datos simulados y datos
reales sin tocar la interfaz.

## Conexión con el backend

El frontend usa los endpoints del backend:

- `POST /api/auth/login` y `POST /api/auth/register`
- `GET /api/students/:id` (resumen del estudiante)
- `GET /api/students/:id/progress` (progreso y recomendación)

Los campos que devuelve el backend están en español (`porcentajeCompletado`,
`notaPromedio`...). El archivo `src/services/dashboardService.ts` los
traduce al formato que usan las pantallas.

### Datos simulados y datos reales

Por defecto el frontend funciona en **modo simulado**, sin necesidad de
backend. Para usar la API real, crear un archivo `frontend/.env.local`
(se puede copiar de `.env.example`) con:

    VITE_USE_MOCK=false
    VITE_API_URL=http://localhost:3000/api

| Dato | Origen en modo real |
|---|---|
| Login, registro, nombre, rol y cursos activos | Backend (base de datos) |
| Porcentaje, módulos, nota promedio, horas, variaciones y recomendación | Backend, todavía simulados allí |
| Actividad reciente, horas por día, dominio por tema, contenido del curso y evaluaciones | Simulados en el frontend (aún no hay endpoints) |

Al cambiar a datos reales, solo se modifica el servicio correspondiente
en `src/services/`; las pantallas no cambian.

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

En modo simulado se puede entrar con `estudiante@example.com` y la
contraseña `estudiante123`.

Para comprobar que el proyecto compila:

    npm run build

## Observaciones técnicas

- La sesión se guarda en `localStorage` y el token del backend dura 2 horas;
  cuando vence, la aplicación cierra la sesión y lleva al login.
- Los ejercicios todavía no envían sus métricas (tiempo, intentos, errores)
  al backend porque no existe el endpoint para registrarlas.
- Las animaciones respetan la preferencia `prefers-reduced-motion` del sistema.

## Responsable de este módulo

Yuleidy A. De Los Santos Reynoso — Frontend y estructura de pantallas