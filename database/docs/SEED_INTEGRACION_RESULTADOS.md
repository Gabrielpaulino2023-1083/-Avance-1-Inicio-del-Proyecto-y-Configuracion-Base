# Seed ampliado: contenido SQL, resultados y motor adaptativo

Preparado el 13 de noviembre de 2026. Este bloque agrega datos de desarrollo;
no es una migración ni modifica las funciones de 001–007.

## Qué agrega y qué conserva

Reutiliza `estudiante.demo@example.com`. Debe existir, estar activo y tener rol
ESTUDIANTE activo y un hash con formato bcrypt. No crea otra cuenta ni altera su
contraseña, nombre, roles o asignaciones existentes. La verificación de formato del
hash no reemplaza una prueba de login; el login de esa cuenta ya fue probado por el equipo.

Crea un curso separado `DEMO-SQL-007`, una edición abierta, una sección de 30 cupos,
una inscripción administrativa para ese estudiante y el módulo publicado `Consultas SQL`.
Usa un administrador activo existente como autor. No asigna nuevos permisos a docentes.
Conserva íntegro `DEMO-003` y los resultados anteriores del estudiante.

| Tema publicado | Actividad | Notas iniciales por intento | Promedio inicial |
|---|---|---|---|
| SQL SELECT | Evaluación | 75, 100, 100 | 91.67 |
| SQL WHERE | Evaluación | 50, 75, 75 | 66.67 |
| SQL JOIN | Práctica | 0, 25, 25 | 16.67 |
| SQL JOIN | Evaluación disponible | Sin intentos | NULL |

Son cuatro actividades publicadas, cuatro preguntas por actividad (tres de selección
única y una de selección múltiple), 16 preguntas y 48 opciones. Los nueve intentos
históricos tienen sus 36 respuestas calificadas. No se dejan intentos EN_CURSO.
Las actividades tienen duración de 30 minutos y no limitan la cantidad de intentos
para facilitar pruebas posteriores. La disponibilidad termina un año después de la carga.

La práctica de SQL JOIN tiene `nota_academica_porcentaje=NULL`, aunque su promedio
sea 16.67. La evaluación sin intentos tiene promedio y nota NULL, no cero. La consulta
final del seed usa LEFT JOIN porque `resultados_actividades` no tiene filas sin intentos.

Estos valores son del curso nuevo, no del Dashboard global: el usuario también conserva
sus resultados anteriores. Nuevos intentos cambiarán los promedios actuales.

## Carga sin editar el archivo

Requisitos: 001–007, `security/001_roles_permisos.sql`, el estudiante demo y al menos un
administrador activo. Usar PostgreSQL local de desarrollo. Ejecutar como `postgres`;
el backend sigue utilizando `plataforma_backend` en su configuración.

Desde la raíz del proyecto en PowerShell:

```powershell
psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -f database/seeds/datos_prueba_integracion_resultados.sql
```

No solicita un hash ni una contraseña del estudiante. La contraseña que puede pedir
psql es la de conexión de `postgres`, no la del usuario de la plataforma.
No volver a ejecutar el seed original de 003 para cargar esta ampliación.
Los archivos están en UTF-8 y el script fija `client_encoding` con `\encoding UTF8`.

Solo si termina con `COMMIT`, comprobar:

```powershell
psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -f database/test/pruebas_seed_integracion_resultados.sql
```

Esperado: seis avisos `OK SEED`, `PRUEBAS SEED INTEGRACION COMPLETADAS` y `ROLLBACK`.
El archivo de pruebas es de solo lectura. Su ROLLBACK no elimina la demo que ya se
confirmó al cargar el seed.

Parámetros opcionales, siempre sin modificar el SQL:

```powershell
# Solo si se desea utilizar otra cuenta EXISTENTE en una BD donde no se cargó esta demo:
psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -v demo_email=estudiante.demo@example.com -f database/seeds/datos_prueba_integracion_resultados.sql

# Referencia histórica explícita; usar una fecha pasada con zona horaria:
psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -v 'fecha_referencia=2026-11-13 12:00:00-04' -f database/seeds/datos_prueba_integracion_resultados.sql
```

La fecha por defecto es el instante de la primera carga. No se aceptan referencias
futuras, infinitas ni los primeros ocho segundos del lunes (no permiten distribuir
todos los intervalos con duración positiva). Si se usa otro correo, pasarlo también
al archivo de pruebas con `-v demo_email=...`.

## Fechas y semanas simuladas

Zona: `America/Santo_Domingo`. Semana ISO: lunes 00:00 local. Se crean:

- Tres intentos en martes, miércoles y jueves de la semana anterior a la referencia.
- Seis intentos distribuidos en la parte ya transcurrida de la semana de referencia.
- Fechas coherentes de inicio, vencimiento, entrega, calificación y respuestas.

Las duraciones normales son 11, 12 y 13 minutos según el tema. Si se carga muy al
inicio del lunes se reducen para no crear fechas futuras ni intervalos solapados.
En un lunes no es posible inventar varios días ya transcurridos de esa misma semana;
los seis intentos actuales se ubican ese lunes. No se incluyen intentos futuros.

Las preguntas se crean y publican con los triggers activos; los intentos se inician,
responden, entregan y califican mediante las funciones existentes. Después, solo el
seed administrativo reubica las fechas de los registros que acaba de crear. No
deshabilita triggers, no altera calificaciones manualmente y no cambia fechas de
intentos anteriores. También fecha la nueva inscripción y el contenido de esta demo.

Es información sintética para pruebas, no evidencia de estudio real. No se modifica
la fecha de creación de la cuenta existente. El backend no recibe permiso para
reescribir fechas históricas. El tiempo entre inicio y entrega sigue siendo tiempo
transcurrido simulado, no una medición de atención o estudio efectivo.

Las fechas quedan congeladas. Volver a ejecutar en otra semana NO mueve el historial
para mantenerlo artificialmente en «esta semana». El resumen muestra las fechas reales
de las semanas cargadas. Para una nueva referencia, planificar otra demo explícitamente;
no borrar registros existentes ni reutilizar sus IDs como atajo.

## Reejecución y protección de datos

La carga completa usa una transacción y un bloqueo asesor para serializar ejecuciones
de este mismo seed. Ante un error, no se confirma una demo parcial.

Si encuentra el curso reservado `DEMO-SQL-007` con su marca de versión/estudiante y
la estructura inicial completa, termina sin cambios. No duplica preguntas, intentos
ni inscripciones. Conserva nuevos intentos y sus resultados.

Si ese código pertenece a otro contenido/estudiante, o faltan piezas esenciales de
la demo original, se detiene. No reconstruye silenciosamente datos modificados ni
reactiva cuentas/roles. La marca está en la descripción del curso de prueba: conservarla
si se quiere que una reejecución reconozca la demo. No es un control de seguridad frente
a un administrador SQL; sirve para evitar sobrescrituras accidentales.

La idempotencia no garantiza que cualquier edición manual de la demo siga pasando
las comprobaciones iniciales. Si se cambian nombres, estados o los primeros resultados,
revisar el fallo: las pruebas no los restauran.

## Uso por backend y frontend

No utilizar IDs fijos. El resumen de carga informa los IDs de inscripción, tema y
actividad. Para identificar el nuevo contexto con una consulta parametrizada:

```sql
SELECT c.id AS curso_id,e.id AS edicion_id,s.id AS seccion_id,
       i.id AS inscripcion_id,m.id AS modulo_id,t.id AS tema_id,t.nombre AS tema
FROM public.usuarios u
JOIN public.inscripciones i ON i.estudiante_id=u.id
JOIN public.secciones s ON s.id=i.seccion_id AND s.edicion_id=i.edicion_id
JOIN public.ediciones_curso e ON e.id=s.edicion_id
JOIN public.cursos c ON c.id=e.curso_id
JOIN public.modulos m ON m.curso_id=c.id
JOIN public.temas t ON t.modulo_id=m.id
WHERE u.id=$1 AND c.codigo='DEMO-SQL-007'
ORDER BY m.orden,t.orden;
```

`$1` es el usuario autorizado por el backend. La autenticación no consiste en aceptar
un ID arbitrario enviado por el navegador. Para mostrar contenido y cuestionarios,
usar las funciones de 007 documentadas en `LECTURA_ESTUDIANTES_007.md`.

El nombre exacto pedido por frontend/motor es `SQL JOIN`. Ese texto ayuda a integrar
la consulta actual por nombre, pero no reemplaza `tema_id` e `inscripcion_id` como
identificadores de contexto. Si existen otros temas con el mismo nombre, el backend
actual podría mezclar sus resultados. Filtrar por contexto al evolucionar ese contrato.

No publicar `opciones_respuestas.es_correcta` ni las plantillas de soluciones al
frontend para calificar allí. Las opciones públicas provienen del cuestionario de 007.
El usuario de BD del backend conserva sus permisos actuales.

## Motor adaptativo: validación realizada

Se ejecutó el motor Python de `main` en commit `80815b2` con las interacciones iniciales
obtenidas del seed. Se usó el formato que hoy construye el backend: una interacción
por intento calificado, `attempts=numero_intento`, `repetitions=numero_intento-1`,
`navigation_count=0`, errores como respuestas de puntaje cero y minutos transcurridos.

| Tema | Promedio | Errores acumulados | Acción obtenida |
|---|---:|---:|---|
| SQL SELECT | 91.67 | 1 | increase_difficulty |
| SQL WHERE | 66.67 | 4 | maintain_difficulty |
| SQL JOIN | 16.67 | 10 | reinforce_topic |

Esto valida estos datos contra ese motor, no la llamada HTTP completa Node–Python
ni una definición definitiva de intentos/repeticiones. `navigation_count=0` continúa
siendo un valor provisional por dato no registrado. No se crean registros de navegación
ni historial de recomendaciones. Las acciones pueden cambiar al agregar intentos,
mezclar contextos o modificar las reglas del motor.

## Pendiente después de la carga local

- Confirmar seed y pruebas en PostgreSQL del equipo.
- Conectar la lectura de 007 y probar el flujo completo desde la interfaz.
- Probar la recomendación mediante el endpoint real con el contexto SQL JOIN.
- Documentar consultas de Dashboard, progreso y límites de las métricas por separado.
- Actualizar README/contrato para enlazar 007 y este seed antes del PR correspondiente.
