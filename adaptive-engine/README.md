# Motor de Aprendizaje Adaptativo

## 1. Descripción

El Motor de Aprendizaje Adaptativo es un módulo desarrollado en Python que forma parte del proyecto final del ITLA denominado **Motor de Aprendizaje Adaptativo Basado en Comportamiento del Estudiante**.

Su propósito es analizar el comportamiento académico de los estudiantes y generar recomendaciones personalizadas según su rendimiento, errores, intentos y repeticiones.

El módulo se encuentra integrado con el backend desarrollado en Node.js, que obtiene los datos académicos almacenados en PostgreSQL y comunica los resultados al frontend desarrollado en React.

## 2. Estado del módulo

El motor cuenta con las siguientes funcionalidades implementadas:

- Recepción y procesamiento de datos en formato JSON.
- Validación de estructuras, campos y valores numéricos.
- Análisis del comportamiento académico mediante Pandas.
- Cálculo de métricas de rendimiento.
- Aplicación de reglas adaptativas.
- Generación de recomendaciones personalizadas.
- Comunicación con el backend Node.js.
- Procesamiento de información procedente de PostgreSQL mediante el backend.
- Manejo controlado de errores.
- Pruebas automatizadas.

El motor utiliza reglas determinísticas. Actualmente no incorpora modelos entrenados de aprendizaje automático.

## 3. Tecnologías utilizadas

- Python 3.
- Pandas: procesamiento y análisis de datos.
- JSON: intercambio de información entre componentes.
- Unittest: ejecución de pruebas automatizadas.
- Scikit-learn: dependencia disponible para futuras ampliaciones, no utilizada en las decisiones adaptativas actuales.

## 4. Estructura del módulo

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

### Archivos principales

| Archivo | Responsabilidad |
|---|---|
| analysis/analyzer.py | Validar las interacciones y calcular las métricas académicas. |
| rules/adaptation_rules.py | Aplicar las reglas adaptativas y generar recomendaciones. |
| engine.py | Coordinar el análisis y la generación de recomendaciones. |
| main.py | Gestionar la ejecución, entrada y salida JSON y los errores controlados. |
| tests/test_engine.py | Verificar el funcionamiento y las validaciones del motor. |
| requirements.txt | Definir las dependencias del módulo. |
| INTEGRATION.md | Documentar el contrato técnico y la integración con la plataforma. |

## 5. Funcionamiento

El motor realiza las siguientes operaciones:

1. Recibe el identificador del estudiante, el tema y sus interacciones académicas.
2. Valida la estructura y los valores recibidos.
3. Procesa las interacciones mediante Pandas.
4. Calcula las métricas de comportamiento académico.
5. Evalúa las reglas de adaptación.
6. Genera una recomendación personalizada.
7. Devuelve el perfil y la recomendación en formato JSON.

### Métricas calculadas

- Promedio de calificaciones.
- Total de errores.
- Promedio de intentos.
- Total de repeticiones.
- Promedio de minutos de estudio.
- Cantidad de interacciones.

## 6. Reglas adaptativas

Las reglas se evalúan en el siguiente orden:

| Acción | Condición | Dificultad |
|---|---|---|
| reinforce_topic | Promedio inferior a 60 % o errores acumulados iguales o superiores a 5. | reduced |
| increase_difficulty | Promedio igual o superior a 85 %, errores acumulados iguales o inferiores a 2 y promedio de intentos igual o inferior a 2. | increased |
| maintain_difficulty | Cuando no se cumplen las condiciones anteriores. | current |

Cuando el estudiante acumula cinco repeticiones o más y la decisión es reforzar el contenido, se recomienda adicionalmente utilizar material complementario con una explicación diferente.

## 7. Instalación

Desde la carpeta principal del repositorio, crear un entorno virtual si todavía no existe:

```powershell
python -m venv .venv
```

Activar el entorno virtual en Windows:

```powershell
.\.venv\Scripts\Activate.ps1
```

Instalar las dependencias:

```powershell
python -m pip install -r adaptive-engine/requirements.txt
```

Estos pasos corresponden a una instalación inicial. No es necesario recrear el entorno virtual si ya está configurado.

## 8. Ejecución independiente

Desde la carpeta principal del repositorio:

```powershell
cd adaptive-engine
python main.py
```

El motor procesa el archivo `data/estudiante_prueba.json` y devuelve el perfil académico junto con la recomendación generada.

### Ejecución mediante entrada estándar

```powershell
Get-Content .\data\estudiante_prueba.json -Raw -Encoding UTF8 | python -X utf8 main.py --stdin
```

Esta modalidad permite recibir información JSON sin modificar el archivo de prueba y constituye el mecanismo de comunicación utilizado por el backend.

## 9. Integración con la plataforma

El motor se integra con Node.js mediante la ejecución de un proceso Python.

El flujo general es el siguiente:

1. El estudiante realiza una actividad desde el frontend.
2. El backend registra y consulta los resultados académicos en PostgreSQL.
3. El backend transforma las interacciones al contrato JSON del motor.
4. Node.js ejecuta Python mediante `engineClient.js`.
5. Python analiza los datos y genera una recomendación.
6. El backend recibe e interpreta el resultado.
7. El backend puede seleccionar una actividad sugerida según la dificultad recomendada y las actividades disponibles.
8. El frontend presenta la recomendación al estudiante.

El motor Python no necesita mantener un servidor independiente en ejecución ni conectarse directamente a PostgreSQL.

La selección de una actividad concreta corresponde al backend. Python determina la acción adaptativa y la dificultad recomendada.

Para consultar el contrato técnico, revisar [INTEGRATION.md](INTEGRATION.md).

## 10. Validaciones y manejo de errores

El motor incorpora validaciones para detectar:

- Estructuras JSON incorrectas.
- Ausencia de campos obligatorios.
- Listas de interacciones vacías.
- Interacciones con estructuras incorrectas.
- Valores no numéricos.
- Valores booleanos en campos numéricos.
- Valores fuera de los rangos permitidos.
- Valores fraccionarios en campos que requieren enteros.
- Valores no finitos, incluyendo NaN e Infinity.

En el modo `--stdin`, los errores controlados se devuelven mediante un objeto JSON por la salida estándar de errores (`stderr`), acompañado de un código de salida distinto de cero.

## 11. Corrección de incidencias QA

El 23 de noviembre de 2026 se completaron las correcciones correspondientes a las siguientes incidencias:

| Incidencia | Corrección |
|---|---|
| INC-03 | Validación de la estructura principal del JSON. |
| INC-04 | Rechazo de NaN, Infinity y -Infinity. |
| INC-05 | Validación de los campos obligatorios student_id y topic. |
| INC-06 | Rechazo de valores booleanos en campos numéricos. |
| INC-07 | Rechazo de valores fraccionarios en campos que requieren enteros. |

Las correcciones fueron integradas en la rama principal mediante el Pull Request #21.

Las reglas adaptativas originales y el contrato de comunicación JSON se conservaron sin modificaciones.

## 12. Pruebas automatizadas

Para ejecutar las pruebas desde la carpeta `adaptive-engine`:

```powershell
python -m unittest discover -s tests -v
```

### Resultados registrados de las pruebas propias

| Indicador | Resultado |
|---|---:|
| Pruebas originales | 6 |
| Nuevas pruebas | 14 |
| Total de pruebas | 20 |
| Pruebas aprobadas | 20 |
| Pruebas fallidas | 0 |
| Tasa de aprobación | 100 % |
| Duración registrada | 10.538 segundos |

También se comprobó la comunicación directa con Node.js utilizando datos válidos e incorrectos.

### Validación independiente de QA

Según el reporte de pruebas del 24 de noviembre de 2026, el módulo Python obtuvo los siguientes resultados:

| Indicador | Resultado |
|---|---:|
| Casos evaluados | 54 |
| Casos aprobados | 54 |
| Casos fallidos | 0 |
| Tasa de aprobación | 100 % |

Estos resultados corresponden a las pruebas registradas hasta esa fecha y no sustituyen la validación integral de la versión definitiva del sistema.

## 13. Alcance y limitaciones

- El motor utiliza reglas determinísticas y no un modelo de aprendizaje automático entrenado.
- Las recomendaciones dependen de la calidad y disponibilidad de los datos académicos.
- El tiempo de estudio registrado representa tiempo transcurrido y no necesariamente tiempo de atención activa.
- El indicador de navegación no interviene en las decisiones adaptativas actuales.
- Los errores acumulados pueden influir en las recomendaciones aunque el rendimiento reciente haya mejorado.
- Las pruebas funcionales verifican el comportamiento del software, pero no demuestran por sí solas su eficacia pedagógica.

## 14. Mejoras futuras

- Evaluar modelos de aprendizaje automático cuando se disponga de suficientes datos.
- Incorporar indicadores adicionales de comportamiento.
- Mejorar la medición del tiempo de estudio activo.
- Evaluar estrategias que otorguen mayor importancia al rendimiento reciente.
- Validar el impacto educativo mediante estudios con estudiantes.

Estas mejoras constituyen posibilidades de evolución y no forman parte de las funcionalidades implementadas actualmente.

## 15. Estado de cierre

El motor adaptativo se encuentra implementado, integrado con el backend y validado mediante pruebas propias e independientes de QA.

Como parte del cierre del Avance 6, se contempla la validación integral de la plataforma y la participación en las pruebas con usuarios.
