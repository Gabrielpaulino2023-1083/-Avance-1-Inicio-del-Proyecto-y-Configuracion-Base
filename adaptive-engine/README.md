# Motor de aprendizaje adaptativo

Estructura inicial del motor de aprendizaje adaptativo.

## Estructura

- `analysis/`: análisis del progreso del estudiante.
- `rules/`: reglas de adaptación.
- `recommendations/`: generación de recomendaciones.
- `models/`: ubicación para modelos entrenados.
- `data/estudiante_prueba.json`: datos de prueba del estudiante.

Las dependencias se añadirán a `requirements.txt` cuando se definan.

## Mejoras de validación y corrección de incidencias QA

Fecha: 23 de noviembre de 2026.

Se fortalecieron las validaciones del motor adaptativo para garantizar el procesamiento adecuado de los datos recibidos desde el backend, conservando las reglas adaptativas originales.

### Incidencias corregidas

- INC-03: validación de la estructura principal del JSON.
- INC-04: rechazo de NaN, Infinity y -Infinity.
- INC-05: validación de los campos obligatorios student_id y topic.
- INC-06: rechazo de valores booleanos en campos numéricos.
- INC-07: rechazo de valores fraccionarios en campos que requieren enteros.

### Archivos modificados

- analysis/analyzer.py: validaciones de estructura, tipos y valores numéricos.
- main.py: lectura y generación de JSON estricto y manejo controlado de errores.
- tests/test_engine.py: ampliación de las pruebas automatizadas.

### Resultados de las pruebas

- Pruebas originales: 6.
- Nuevas pruebas: 14.
- Total de pruebas automatizadas: 20.
- Pruebas aprobadas: 20.
- Pruebas fallidas: 0.
- Tasa de aprobación: 100 %.
- Duración registrada: 10.538 segundos.

### Integración con Node.js

Se comprobó la comunicación directa mediante engineClient.js utilizando datos válidos y datos incorrectos. El backend recibió correctamente la recomendación adaptativa y el error controlado generado por Python.

Las reglas adaptativas originales y el contrato de comunicación JSON se conservaron sin modificaciones.

### Estado de validación

Las cinco incidencias fueron comprobadas satisfactoriamente mediante pruebas locales. Queda pendiente la validación independiente del equipo de QA y la ejecución de las pruebas integrales del sistema.