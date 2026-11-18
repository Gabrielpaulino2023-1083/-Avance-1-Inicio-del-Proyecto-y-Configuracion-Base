
# Integración del Motor de Aprendizaje Adaptativo

## 1. Descripción

El Motor de Aprendizaje Adaptativo es un módulo desarrollado en Python que analiza las interacciones académicas de los estudiantes y genera recomendaciones personalizadas.

Actualmente funciona mediante reglas determinísticas y permite intercambiar información en formato JSON.

El módulo funciona de manera independiente. Su integración definitiva con Node.js y PostgreSQL está pendiente.

## 2. Tecnologías

- Python 3
- Pandas
- JSON
- Unittest
- Scikit-learn (instalado, sin modelos entrenados actualmente)

## 3. Componentes principales

- `main.py`: punto de entrada; admite un archivo de prueba o JSON por entrada estándar.
- `engine.py`: coordina el análisis y las recomendaciones.
- `analysis/analyzer.py`: valida las interacciones y calcula métricas.
- `rules/adaptation_rules.py`: determina la acción adaptativa.
- `data/estudiante_prueba.json`: datos de ejemplo.
- `tests/test_engine.py`: pruebas automatizadas.

## 4. Contrato de entrada JSON

El motor espera un objeto con:

- `student_id`: identificador del estudiante.
- `topic`: tema evaluado.
- `interactions`: lista con una o más interacciones.

Cada interacción debe contener:

| Campo | Descripción | Restricción |
|---|---|---|
| `study_minutes` | Minutos de estudio | Número >= 0 |
| `errors` | Errores registrados | Número >= 0 |
| `attempts` | Intentos realizados | Número >= 1 |
| `repetitions` | Repeticiones del contenido | Número >= 0 |
| `navigation_count` | Navegaciones registradas | Número >= 0 |
| `score_percentage` | Calificación porcentual | Entre 0 y 100 |

Ejemplo:

```json
{
  "student_id": 1,
  "topic": "SQL JOIN",
  "interactions": [
    {
      "study_minutes": 18,
      "errors": 4,
      "attempts": 3,
      "repetitions": 2,
      "navigation_count": 8,
      "score_percentage": 45
    }
  ]
}
```

## 5. Procesamiento

1. Recibir el JSON.
2. Validar la existencia de interacciones y sus campos obligatorios.
3. Convertir los campos de las interacciones a valores numéricos.
4. Comprobar los rangos permitidos.
5. Calcular las métricas del estudiante.
6. Aplicar las reglas de adaptación.
7. Devolver el perfil y la recomendación.

### Métricas calculadas

- `average_score`: promedio de calificaciones.
- `total_errors`: suma de errores.
- `average_attempts`: promedio de intentos.
- `total_repetitions`: suma de repeticiones.
- `average_study_minutes`: promedio de minutos de estudio.
- `total_interactions`: cantidad de interacciones.

## 6. Reglas de adaptación

Las reglas se evalúan en este orden:

### Reforzar contenido

Acción: `reinforce_topic`

Dificultad: `reduced`

Se aplica cuando:

- El promedio de calificaciones es inferior a 60 %, o
- Los errores acumulados son cinco o más.

Cuando existen cinco o más repeticiones y corresponde reforzar, se agrega una recomendación de material complementario.

### Aumentar dificultad

Acción: `increase_difficulty`

Dificultad: `increased`

Se aplica cuando se cumplen todas estas condiciones:

- Calificación promedio >= 85 %.
- Errores acumulados <= 2.
- Promedio de intentos <= 2.

### Mantener dificultad

Acción: `maintain_difficulty`

Dificultad: `current`

Se aplica cuando no se cumplen las condiciones anteriores.

## 7. Contrato de salida JSON

Cuando el procesamiento es exitoso, el motor devuelve:

- `profile`: estadísticas del comportamiento académico.
- `recommendation`: decisión adaptativa, dificultad, justificación y recomendación.

Ejemplo para los datos de entrada anteriores:

```json
{
  "profile": {
    "student_id": 1,
    "topic": "SQL JOIN",
    "average_score": 45.0,
    "total_errors": 4,
    "average_attempts": 3.0,
    "total_repetitions": 2,
    "average_study_minutes": 18.0,
    "total_interactions": 1
  },
  "recommendation": {
    "student_id": 1,
    "topic": "SQL JOIN",
    "action": "reinforce_topic",
    "difficulty": "reduced",
    "reason": "Puntuación promedio: 45.0%; errores acumulados: 4; intentos promedio: 3.0.",
    "recommendation": "Se recomienda reforzar el tema SQL JOIN con explicaciones y ejercicios guiados."
  }
}
```

## 8. Ejecución

Todos los comandos siguientes se ejecutan desde `adaptive-engine`.

### Prueba local

```powershell
python main.py
```

Utiliza `data/estudiante_prueba.json` y muestra el perfil y la recomendación.

### Entrada estándar JSON

```powershell
Get-Content .\data\estudiante_prueba.json -Raw | python main.py --stdin
```

Con `--stdin`, el motor:

1. Lee un objeto JSON desde la entrada estándar.
2. Procesa las interacciones.
3. Escribe un único objeto JSON en la salida estándar (`stdout`).

## 9. Integración propuesta con Node.js

Flujo previsto:

1. El frontend registra las actividades del estudiante.
2. Node.js obtiene los datos necesarios desde PostgreSQL.
3. El backend transforma esos datos al contrato JSON del motor.
4. Node.js inicia el proceso Python.
5. Envía el JSON mediante la entrada estándar (`stdin`).
6. Python analiza las interacciones y genera una recomendación.
7. Python devuelve el resultado mediante `stdout`.
8. Node.js interpreta la respuesta y la pone a disposición del frontend.

Se propone evaluar un endpoint como:

`POST /api/adaptive/analyze`

**Importante:** este endpoint es una propuesta y todavía debe acordarse con el responsable del backend.

La integración deberá contemplar el manejo de errores, los tiempos de espera y la finalización del proceso Python.

## 10. Manejo de errores

El motor valida las interacciones y sus valores numéricos.

Entre los errores detectados se encuentran:

- Lista de interacciones vacía.
- Campos obligatorios faltantes en las interacciones.
- Valores no numéricos.
- Valores fuera de los rangos permitidos.

En modo `--stdin`, cuando ocurre un error controlado:

- Se escribe un objeto JSON con la propiedad `error` en `stderr`.
- El proceso termina con código de salida `1`.

El manejo de otros errores no controlados deberá fortalecerse en futuras mejoras.

## 11. Pruebas automatizadas

El módulo cuenta con seis pruebas implementadas mediante `unittest`:

1. Rendimiento bajo: refuerzo de contenido.
2. Rendimiento medio: mantenimiento de dificultad.
3. Rendimiento alto: aumento de dificultad.
4. Interacciones vacías: se detecta el error.
5. Calificación fuera del rango: se detecta el error.
6. Campo obligatorio faltante: se detecta el error.

Ejecutar desde `adaptive-engine`:

```powershell
python -m unittest discover -s tests -v
```

## 12. Estado actual y pendientes

### Implementado

- Análisis de interacciones con Pandas.
- Cálculo de métricas académicas.
- Validación básica de datos.
- Tres decisiones adaptativas.
- Recomendaciones personalizadas.
- Entrada y salida JSON.
- Seis pruebas automatizadas.

### Pendiente

- Adaptar los datos reales de actividades e intentos de PostgreSQL.
- Integrar el módulo con el backend Node.js.
- Ampliar validaciones y pruebas.
- Ejecutar pruebas de integración entre componentes.
- Evaluar modelos de aprendizaje automático cuando existan datos apropiados.

El módulo actual utiliza reglas determinísticas y no debe describirse como un modelo de machine learning entrenado.
