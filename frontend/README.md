# Frontend — Motor de Aprendizaje Adaptativo

Esta carpeta contiene la interfaz web del proyecto, construida con
React y TypeScript. Es la parte con la que el estudiante va a
interactuar directamente: iniciar sesión, ver el contenido de sus
cursos, revisar resultados de evaluaciones y consultar su progreso.

Por ahora las pantallas están en blanco a propósito. Lo que se dejó
listo en esta primera entrega fue la estructura del proyecto, la
navegación entre pantallas y el entorno de desarrollo funcionando,
para que en las próximas etapas solo haga falta ir conectando cada
pantalla con datos reales.

## Qué contiene esta carpeta

Dentro de `src/` hay una carpeta por cada pantalla (`Login`,
`Dashboard`, `Content`, `Results`, `Progress`), cada una con su propio
componente. La navegación entre ellas se maneja con React Router, y
el archivo `components/Layout/AppLayout.tsx` es el que dibuja la barra
de navegación de arriba y controla qué pantalla se muestra según la
ruta.

- `/login` — inicio de sesión del estudiante
- `/` — dashboard, lo primero que se ve tras iniciar sesión
- `/contenido` — cursos y ejercicios
- `/resultados` — resultados de evaluaciones
- `/progreso` — progreso y recomendaciones del motor adaptativo

## Tecnologías

React.js, TypeScript y React Router, usando Vite como entorno de
desarrollo.

## Cómo correrlo

    cd frontend
    npm install
    npm run dev

Esto levanta la aplicación en http://localhost:5173

## Responsable de este módulo

Yuleidy A. De Los Santos Reynoso - Frontend y estructura de pantallas