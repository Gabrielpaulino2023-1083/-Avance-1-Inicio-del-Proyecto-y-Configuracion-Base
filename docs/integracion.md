# Integración del sistema

## Integración actual

En esta primera etapa, el proyecto cuenta con dos componentes principales: el Frontend desarrollado con React y TypeScript y el motor de aprendizaje adaptativo desarrollado en Python.

El Frontend integra las pantallas de Login, Dashboard, Contenido, Resultados y Progreso mediante React Router. Esto permite navegar entre los diferentes módulos desde una misma aplicación sin recargar completamente la página.

El motor adaptativo se encuentra organizado de forma independiente dentro de `adaptive-engine/`, con módulos destinados al análisis de información, reglas de adaptación, recomendaciones, modelos y datos de prueba.

## Integración prevista

A medida que avance el proyecto, los componentes se conectarán mediante el Backend y una API. La arquitectura prevista es:

Frontend → API / Backend → Base de datos → Motor de aprendizaje adaptativo

Esta integración permitirá que la información generada por la interacción del estudiante, como tiempo de estudio, errores, repeticiones, navegación y resultados, pueda ser procesada por el motor adaptativo para generar recomendaciones y ajustar el nivel de dificultad.
