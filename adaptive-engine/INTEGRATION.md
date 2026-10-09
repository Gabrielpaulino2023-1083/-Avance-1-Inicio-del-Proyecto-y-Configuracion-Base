\# Integración del Motor de Aprendizaje Adaptativo



\## 1. Descripción



El Motor de Aprendizaje Adaptativo es un módulo desarrollado en Python que analiza el comportamiento académico de los estudiantes y genera recomendaciones personalizadas.



Actualmente funciona mediante reglas de adaptación y está preparado para recibir información JSON desde otros programas.



\## 2. Tecnologías



\- Python 3

\- Pandas

\- Scikit-learn (instalado, pendiente de implementación de modelos)

\- JSON para el intercambio de información



\## 3. Archivos principales



\- `main.py`: punto de entrada del motor.

\- `engine.py`: coordina el análisis y la generación de recomendaciones.

\- `analysis/analyzer.py`: analiza el comportamiento y calcula las métricas.

\- `rules/adaptation\_rules.py`: aplica las reglas de adaptación.

\- `data/estudiante\_prueba.json`: contiene datos de prueba.

\- `requirements.txt`: dependencias del proyecto.



\## 4. Datos de entrada



El motor recibe un objeto JSON con el identificador del estudiante, el tema y sus interacciones.



Ejemplo:



```json

{

&#x20; "student\_id": 1,

&#x20; "topic": "SQL JOIN",

&#x20; "interactions": \[

&#x20;   {

&#x20;     "study\_minutes": 18,

&#x20;     "errors": 4,

&#x20;     "attempts": 3,

&#x20;     "repetitions": 2,

&#x20;     "navigation\_count": 8,

&#x20;     "score\_percentage": 45

&#x20;   }

&#x20; ]

}

```



\## 5. Procesamiento



El motor realiza las siguientes operaciones:



1\. Recibe los datos del estudiante.

2\. Valida los campos y sus valores.

3\. Calcula las métricas de comportamiento.

4\. Evalúa las reglas de adaptación.

5\. Genera una recomendación personalizada.

6\. Devuelve el resultado en formato JSON.



\## 6. Reglas de adaptación



\*\*Reforzar contenido (`reinforce\_topic`):\*\*



Se aplica cuando la calificación promedio es inferior a 60 % o los errores acumulados son cinco o más.



\*\*Aumentar dificultad (`increase\_difficulty`):\*\*



Se aplica cuando la calificación promedio es igual o superior a 85 %, los errores acumulados son dos o menos y el promedio de intentos es dos o menos.



\*\*Mantener dificultad (`maintain\_difficulty`):\*\*



Se aplica cuando no se cumplen las condiciones anteriores.



Las reglas se evalúan en ese orden.



\## 7. Datos de salida



El motor devuelve un objeto JSON con dos propiedades principales:



\- `profile`: estadísticas calculadas del estudiante.

\- `recommendation`: acción adaptativa, dificultad, justificación y recomendación.



Ejemplo:



```json

{

&#x20; "profile": {

&#x20;   "student\_id": 1,

&#x20;   "topic": "SQL JOIN",

&#x20;   "average\_score": 45.0,

&#x20;   "total\_errors": 4,

&#x20;   "average\_attempts": 3.0,

&#x20;   "total\_repetitions": 2,

&#x20;   "average\_study\_minutes": 18.0,

&#x20;   "total\_interactions": 1

&#x20; },

&#x20; "recommendation": {

&#x20;   "student\_id": 1,

&#x20;   "topic": "SQL JOIN",

&#x20;   "action": "reinforce\_topic",

&#x20;   "difficulty": "reduced",

&#x20;   "reason": "Puntuación promedio: 45.0%; errores acumulados: 4; intentos promedio: 3.0.",

&#x20;   "recommendation": "Se recomienda reforzar el tema SQL JOIN con explicaciones y ejercicios guiados."

&#x20; }

}

```



\## 8. Ejecución del motor



Desde la carpeta `adaptive-engine`:



\*\*Prueba local:\*\*



```powershell

python main.py

```



\*\*Procesamiento de JSON mediante entrada estándar:\*\*



```powershell

Get-Content .\\data\\estudiante\_prueba.json -Raw | python main.py --stdin

```



El segundo comando permite enviar datos JSON al motor sin modificar el archivo de prueba.



\## 9. Integración prevista con Node.js



El backend será responsable de recibir los datos del estudiante y enviarlos al motor Python.



Flujo propuesto:



1\. Node.js recibe los datos de comportamiento.

2\. El backend ejecuta el proceso Python.

3\. Envía el JSON por la entrada estándar.

4\. Python procesa la información.

5\. Python devuelve un JSON por la salida estándar.

6\. Node.js interpreta la respuesta y la entrega al frontend.



Para la integración se propone un endpoint `POST /api/adaptive/analyze`, cuya implementación deberá acordarse con el responsable del backend.



La ejecución desde Node.js deberá controlar errores, tiempos de espera y finalización del proceso.



\## 10. Manejo de errores



El motor valida:



\- Existencia de interacciones.

\- Presencia de campos obligatorios.

\- Valores numéricos válidos.

\- Rangos permitidos.



Los errores se devuelven en formato JSON por la salida de errores (`stderr`) y el proceso termina con código distinto de cero.



\## 11. Pruebas realizadas



Se realizaron seis pruebas manuales exitosas:



1\. Rendimiento bajo: refuerzo de contenido.

2\. Rendimiento medio: mantenimiento de dificultad.

3\. Rendimiento alto: aumento de dificultad.

4\. Estudiante sin interacciones: error detectado.

5\. Calificación fuera del rango permitido: error detectado.

6\. Campo obligatorio faltante: error detectado.



\## 12. Estado actual



El motor funciona de manera independiente y procesa datos JSON.



Pendiente:



\- Pruebas automatizadas.

\- Integración real con Node.js.

\- Conexión con datos procedentes de PostgreSQL mediante el backend.

\- Implementación futura de modelos de aprendizaje automático.



El motor actual utiliza reglas determinísticas; todavía no se ha entrenado un modelo de machine learning.



