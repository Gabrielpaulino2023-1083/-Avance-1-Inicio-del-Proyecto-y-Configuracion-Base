
# Motor de Aprendizaje Adaptativo

## Descripción
Módulo desarrollado en Python para analizar las interacciones académicas de los estudiantes y generar recomendaciones personalizadas mediante reglas de adaptación.

Forma parte de la plataforma educativa del Grupo 4 y está diseñado para comunicarse con el backend Node.js mediante datos JSON.

## Tecnologías
- Python
- Pandas
- JSON
- unittest (pruebas automatizadas)

El archivo requirements.txt también incluye scikit-learn, aunque las reglas actuales no utilizan un modelo entrenado de aprendizaje automático.

## Estructura del módulo
- main.py: punto de entrada, lectura de JSON y manejo de errores.
- engine.py: coordinación del análisis y generación de recomendaciones.
- analysis/analyzer.py: validación y cálculo de métricas.
- rules/adaptation_rules.py: reglas de adaptación.
- data/estudiante_prueba.json: datos de ejemplo.
- tests/test_engine.py: pruebas automatizadas.
- requirements.txt: dependencias del módulo.

## Datos de entrada
El motor recibe un objeto JSON con:
- student_id: identificador del estudiante.
- topic: tema evaluado.
- interactions: lista de interacciones del estudiante.

Cada interacción requiere seis campos numéricos:
- study_minutes: tiempo de estudio en minutos.
- errors: cantidad de errores.
- attempts: número de intento.
- repetitions: repeticiones.
- navigation_count: cantidad de navegaciones.
- score_percentage: puntuación porcentual entre 0 y 100.

Ejemplo:

```json
{
  "student_id": 1,
  "topic": "SQL JOIN",
  "interactions": [
    {
      "study_minutes": 20,
      "errors": 2,
      "attempts": 1,
      "repetitions": 0,
      "navigation_count": 3,
      "score_percentage": 55
    }
  ]
}
```

## Procesamiento
El analizador calcula:
- Puntuación promedio.
- Errores acumulados.
- Promedio de intentos.
- Repeticiones acumuladas.
- Tiempo promedio de estudio.
- Número de interacciones.

## Reglas de adaptación

### Rendimiento bajo
Cuando la puntuación promedio es inferior a 60% o los errores acumulados son cinco o más:
- Acción: `reinforce_topic`
- Dificultad: `reduced`

### Rendimiento alto
Cuando la puntuación promedio es igual o superior a 85%, los errores son dos o menos y el promedio de intentos es dos o menos:
- Acción: `increase_difficulty`
- Dificultad: `increased`

### Rendimiento intermedio
Cuando no se cumple ninguna de las condiciones anteriores:
- Acción: `maintain_difficulty`
- Dificultad: `current`

Si existen cinco o más repeticiones acumuladas y corresponde reforzar el tema, se añade una recomendación de material complementario.

## Respuesta del motor
El motor devuelve un JSON con dos objetos:
- `profile`: métricas calculadas del estudiante.
- `recommendation`: acción, dificultad, motivo y recomendación.

## Instalación
Desde la carpeta `adaptive-engine`:

```powershell
python -m pip install -r requirements.txt
```

## Ejecución independiente
```powershell
python main.py
```

## Ejecución mediante JSON por stdin
```powershell
Get-Content .\data\estudiante_prueba.json -Raw | python main.py --stdin
```

En modo `--stdin`, la salida estándar contiene el resultado JSON. Los errores de validación se envían a la salida de errores y el proceso termina con código distinto de cero.

## Pruebas automatizadas
Desde la carpeta `adaptive-engine`:

```powershell
python -m unittest discover -s tests -v
```

Se ejecutaron satisfactoriamente seis pruebas el 13 de noviembre de 2026:
1. Rendimiento bajo.
2. Rendimiento medio.
3. Rendimiento alto.
4. Puntuación fuera de rango.
5. Interacciones vacías.
6. Campo obligatorio faltante.

Resultado: **6 pruebas aprobadas, 0 errores**.

También se verificó manualmente:
- Procesamiento de JSON por `stdin`.
- Rechazo de puntuación 150.
- Rechazo de interacción sin `score_percentage`.

## Integración con Node.js
El backend está preparado para ejecutar el motor como un proceso Python y enviarle datos JSON mediante `stdin`.

La ejecución completa PostgreSQL → Node.js → Python → React todavía requiere validación conjunta con los responsables de backend, base de datos y frontend.

## Limitaciones actuales
- El motor utiliza reglas determinísticas; no se ha implementado un modelo predictivo entrenado.
- `navigation_count` todavía se proporciona con valor provisional 0 desde el backend.
- La integración de extremo a extremo no se considera verificada hasta ejecutar pruebas conjuntas.

## Responsable
Daniel Abdias Beltre Galvez — Desarrollo y validación del motor adaptativo en Python.
  