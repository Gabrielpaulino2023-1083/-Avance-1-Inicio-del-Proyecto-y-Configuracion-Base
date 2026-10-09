# Arquitectura inicial

El proyecto se encuentra dividido inicialmente en módulos independientes para facilitar el desarrollo colaborativo y la integración progresiva.

## Frontend

Ubicación: `frontend/`

Tecnologías actuales:

- React
- TypeScript
- React Router
- Vite

Contiene la interfaz y las pantallas con las que interactuará el estudiante.

## Motor adaptativo

Ubicación: `adaptive-engine/`

Tecnología principal:

- Python

Su estructura incluye módulos de análisis, reglas de adaptación, recomendaciones, modelos y datos de prueba. Su función será procesar la información del estudiante para apoyar la adaptación de contenidos y dificultad.

## Componentes previstos

Según la planificación general del proyecto, posteriormente se incorporarán el Backend, la API y la base de datos para comunicar el Frontend con el motor adaptativo.

Flujo previsto:

Frontend → Backend / API → Base de datos → Motor adaptativo → Recomendaciones y adaptación
