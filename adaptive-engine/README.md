
# Motor de Aprendizaje Adaptativo

Módulo desarrollado en Python para analizar el comportamiento académico de estudiantes y generar recomendaciones adaptativas según su rendimiento.

Forma parte del proyecto **Motor de Aprendizaje Adaptativo Basado en Comportamiento del Estudiante**, desarrollado como proyecto final del ITLA.

## Estado del módulo

El motor funciona actualmente de manera independiente mediante reglas de adaptación.

Permite:

- Recibir información del estudiante en formato JSON.
- Validar las interacciones académicas registradas.
- Analizar el rendimiento utilizando Pandas.
- Calcular métricas de comportamiento.
- Generar recomendaciones personalizadas.
- Devolver resultados JSON para una futura integración con Node.js.
- Ejecutar pruebas automatizadas.

**Nota:** El motor utiliza reglas determinísticas. Todavía no incorpora modelos entrenados de aprendizaje automático.

## Tecnologías utilizadas

- Python 3
- Pandas
- JSON
- Unittest
- Scikit-learn (dependencia instalada para desarrollo futuro)

## Estructura del módulo

```text
adaptive-engine/
├── analysis/
│   └── analyzer.py
├── rules/
│   └── adaptation_rules.py
├── recommendations/
├── models/
├── data/
│   └── estudiante_prueba.json
├── tests/
│   └── test_engine.py
├── engine.py
├── main.py
├── requirements.txt
├── README.md
└── INTEGRATION.md
```

## Funcionamiento

El motor sigue este proceso:

1. Recibe el identificador del estudiante, el tema y sus interacciones.
2. Valida los datos recibidos.
3. Calcula las métricas académicas y de comportamiento.
4. Evalúa las reglas adaptativas.
5. Genera una recomendación según el rendimiento.
6. Devuelve un objeto JSON con el perfil y la recomendación.

### Métricas analizadas

- Promedio de calificaciones.
- Total de errores.
- Promedio de intentos.
- Total de repeticiones.
- Promedio de minutos de estudio.
- Cantidad de interacciones.

### Decisiones adaptativas

| Acción | Descripción |
|---|---|
| `reinforce_topic` | Recomienda reforzar el tema y reducir la dificultad. |
| `maintain_difficulty` | Mantiene la dificultad actual. |
| `increase_difficulty` | Recomienda aumentar la dificultad. |

Las decisiones dependen del rendimiento, los errores y los intentos del estudiante.

## Instalación

Desde la carpeta principal del repositorio, entrar al módulo:

```powershell
cd adaptive-engine
```

Instalar las dependencias:

```powershell
python -m pip install -r requirements.txt
```

Se recomienda utilizar un entorno virtual de Python.

## Ejecución

Desde `adaptive-engine`, ejecutar:

```powershell
python main.py
```

Este comando procesa los datos almacenados en `data/estudiante_prueba.json` y muestra el perfil del estudiante junto con la recomendación generada.

### Procesar datos mediante JSON

El motor también acepta información por entrada estándar:

```powershell
Get-Content .\data\estudiante_prueba.json -Raw | python main.py --stdin
```

En este modo, la respuesta se devuelve como un único objeto JSON por la salida estándar.

Esta funcionalidad facilita la futura comunicación con el backend Node.js.

## Pruebas automatizadas

El módulo cuenta con seis pruebas automatizadas que verifican:

1. Rendimiento bajo.
2. Rendimiento medio.
3. Rendimiento alto.
4. Ausencia de interacciones.
5. Calificación fuera del rango permitido.
6. Ausencia de un campo obligatorio.

Para ejecutarlas desde `adaptive-engine`:

```powershell
python -m unittest discover -s tests -v
```

## Integración con la plataforma

El módulo está preparado para intercambiar información JSON con otros componentes.

La integración definitiva con el backend Node.js y los datos de PostgreSQL todavía está pendiente.

Para conocer el contrato de entrada y salida, las reglas y el flujo de integración propuesto, consultar:

[INTEGRATION.md](INTEGRATION.md)

## Próximas mejoras

- Fortalecer las validaciones.
- Ampliar las pruebas automatizadas.
- Adaptar los datos de actividades e intentos provenientes del backend.
- Integrar el motor con Node.js.
- Evaluar la incorporación futura de modelos de aprendizaje automático.
