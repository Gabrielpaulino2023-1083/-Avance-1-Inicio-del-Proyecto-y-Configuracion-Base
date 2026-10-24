# Contrato de integración de la base de datos

**Referencia:** BD-003-v1 · **Fecha:** 23 de octubre de 2026.

**Destinatarios:** responsables de backend, motor adaptativo, frontend, QA y agentes de IA que colaboren con ellos.

Este documento describe el comportamiento existente para integrar los módulos sin inventar tablas, columnas, permisos o reglas. El README contiene la instalación y el historial de verificaciones; este contrato contiene las decisiones que una implementación debe respetar.

## 1. Alcance y autoridad

La referencia de esta versión son los archivos:

- `database/migrations/001_estructura_academica_inicial.sql`
- `database/migrations/002_modulos_temas.sql`
- `database/migrations/003_actividades_intentos_respuestas.sql` corregida
- `database/security/001_roles_permisos.sql` corregido

Se instalaron en una base nueva: **17 tablas, una vista, diez funciones y nueve triggers**. Se comprobó el recorrido funcional bajo `plataforma_backend`. La integración HTTP/React/Python no queda certificada por esa prueba.

Las migraciones definen lo que existe; los permisos definen lo que la cuenta de conexión puede hacer; este contrato explica cómo usarlo. Ante una discrepancia, revisar las fuentes y acordar la corrección, no modificar el esquema por una suposición. La ejecución completa del archivo consolidado de regresión fue confirmada por el responsable de base de datos; los casos incluidos finalizaron con el resultado esperado.

No se busca impedir toda evolución. Una necesidad no cubierta se presenta como un cambio explícito, separado y revisable, sin alterar silenciosamente contratos ya utilizados.

## 2. Instrucciones para desarrolladores y agentes de IA

1. Leer este contrato y las migraciones antes de escribir consultas o modelos.
2. Mantener los nombres SQL existentes. Los nombres del JSON pueden adaptarse en el servicio sin renombrar tablas.
3. Usar las funciones operativas para iniciar, guardar, entregar y calificar. No reemplazarlas por inserciones o actualizaciones directas.
4. No agregar tablas `users`, `topics`, `interactions` o `recommendations` suponiendo que ya forman parte del esquema. `usuarios` y `temas` ya existen; interacciones y recomendaciones todavía no.
5. No conceder privilegios para hacer desaparecer un error de permisos. Verificar primero si se está omitiendo la operación controlada.
6. No utilizar `postgres` como conexión habitual de Express ni guardar credenciales reales en el repositorio.
7. Obtener el estudiante desde la identidad autenticada. No confiar en `estudiante_id` proporcionado libremente por el navegador.
8. No devolver hashes, claves correctas ni explicaciones que revelen respuestas antes del momento autorizado. No devolver automáticamente todas las columnas de una consulta.
9. No afirmar que un endpoint existe porque este documento contiene una consulta. Este contrato no crea rutas HTTP ni fija sus DTOs.
10. Ante un dato ausente, explicar la carencia. No fabricar métricas o guardar ceros para hacer pasar una validación del motor.
11. No editar migraciones ya adoptadas para actualizar bases existentes. Proponer una migración incremental y revisar compatibilidad.
12. Documentar qué se probó y qué sigue pendiente. No equiparar pruebas SQL locales con integración completa.

## 3. Mapa de entidades

- Organización académica: `cursos → ediciones_curso → secciones → inscripciones`.
- Estructura educativa: `cursos → modulos → temas`.
- Actividad: una sección y un tema del mismo curso.
- Evaluación de resultados: `actividades → preguntas → opciones_respuestas`.
- Participación: `inscripciones → intentos → respuestas → respuesta_opciones`.

Un rol permite una función general; la asignación determina dónde se ejerce. Tener rol docente no autoriza a editar todos los cursos. `curso_editores` autoriza edición compartida y `seccion_docentes` identifica responsables de sección; su autorización completa sigue pendiente en los servicios.

Las personas pueden tener varios roles activos. La incompatibilidad acordada es enseñar y estudiar en la misma sección, no la prohibición global de tener ambos roles. Esa incompatibilidad todavía no está implementada en este bloque.

Una inscripción representa al estudiante en una edición. No crear otra inscripción al cambiarlo de sección: la operación de traslado e historial está pendiente. Los intentos anteriores conservan su actividad original.

## 4. Diccionario de tablas existentes

Todos los nombres pertenecen al esquema `public`. Salvo `respuesta_opciones`, las tablas tienen `id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY`. No suponer IDs fijos ni secuencias sin huecos.

| Tabla | Columnas adicionales a `id` |
|---|---|
| `usuarios` | `nombre`, `apellido`, `email`, `password_hash`, `activo`, `creado_en`, `actualizado_en` |
| `roles` | `codigo`, `nombre` |
| `usuario_roles` | `usuario_id`, `rol_id`, `activo`, `asignado_por`, `asignado_en`, `desactivado_en` |
| `cursos` | `codigo`, `nombre`, `descripcion`, `estado`, `creado_por`, `creado_en`, `actualizado_en` |
| `curso_editores` | `curso_id`, `usuario_id`, `activo`, `asignado_por`, `asignado_en` |
| `ediciones_curso` | `curso_id`, `codigo`, `nombre`, `fecha_inicio`, `fecha_fin`, `inscripcion_desde`, `inscripcion_hasta`, `estado`, `creado_por`, `creado_en` |
| `secciones` | `edicion_id`, `codigo`, `cupo_maximo`, `estado`, `creado_por`, `creado_en` |
| `seccion_docentes` | `seccion_id`, `usuario_id`, `activo`, `asignado_por`, `asignado_en` |
| `inscripciones` | `estudiante_id`, `edicion_id`, `seccion_id`, `estado`, `origen`, `registrado_por`, `inscrito_en`, `cerrado_en` |
| `modulos` | `curso_id`, `nombre`, `descripcion`, `orden`, `estado`, `creado_por`, `creado_en`, `actualizado_en` |
| `temas` | `modulo_id`, `nombre`, `descripcion`, `orden`, `estado`, `creado_por`, `creado_en`, `actualizado_en` |
| `actividades` | `seccion_id`, `tema_id`, `titulo`, `instrucciones`, `finalidad`, `metodo_calificacion`, `max_intentos`, `duracion_minutos`, `disponible_desde`, `disponible_hasta`, `estado`, `creado_por`, `creado_en`, `actualizado_en` |
| `preguntas` | `actividad_id`, `enunciado`, `tipo`, `orden`, `puntaje_maximo`, `explicacion` |
| `opciones_respuestas` | `pregunta_id`, `texto`, `orden`, `es_correcta` |
| `intentos` | `actividad_id`, `inscripcion_id`, `numero_intento`, `estado`, `iniciado_en`, `vence_en`, `entregado_en`, `motivo_entrega`, `calificado_en`, `puntaje_obtenido`, `puntaje_maximo` |
| `respuestas` | `intento_id`, `pregunta_id`, `actividad_id`, `creado_en`, `actualizado_en`, `calificado_en`, `puntaje_obtenido` |
| `respuesta_opciones` | Sin `id`: `respuesta_id`, `pregunta_id`, `opcion_id`; clave primaria `(respuesta_id, opcion_id)` |

Reglas transversales:

- Correo único sobre `lower(email)` y sin espacios exteriores. Los textos obligatorios no admiten cadena vacía ni solo espacios.
- Puntajes `NUMERIC(10,2)`. Mantener cálculos decimales; el backend debe comprobar cómo `pg` representa `NUMERIC` antes de serializar JSON. No asumir que siempre llega como número JavaScript.
- Fechas de tipo `TIMESTAMPTZ`. Usar fechas con zona explícita; para el navegador se recomienda ISO 8601 con zona. No comparar cadenas de fecha locales.
- Orden entero desde 1, único por padre. Los nombres no son claves únicas.
- Código de edición único por curso y código de sección único por edición.
- Una inscripción por estudiante y edición, incluso si está cerrada.
- `ON DELETE RESTRICT` protege referencias; no representa una política completa de borrado lógico para todas las tablas.
- Los valores predeterminados de `actualizado_en` no crean una actualización automática general.

## 5. Valores y significado de NULL

| Campo o entidad | Valores |
|---|---|
| `roles.codigo` | `ESTUDIANTE`, `DOCENTE`, `ADMINISTRADOR` |
| Curso | `BORRADOR`, `ACTIVO`, `ARCHIVADO` |
| Edición | `PLANIFICADA`, `ABIERTA`, `EN_CURSO`, `FINALIZADA`, `CANCELADA` |
| Sección | `ABIERTA`, `CERRADA`, `CANCELADA` |
| Inscripción | `ACTIVA`, `RETIRADA`, `COMPLETADA`, `CANCELADA` |
| `inscripciones.origen` | `AUTONOMA`, `ADMINISTRATIVA` |
| Módulo, tema, actividad | `BORRADOR`, `PUBLICADO`, `ARCHIVADO` |
| `actividades.finalidad` | `PRACTICA`, `EVALUACION` |
| `actividades.metodo_calificacion` | Solo `PROMEDIO` |
| `preguntas.tipo` | `SELECCION_UNICA`, `SELECCION_MULTIPLE` |
| Intento | `EN_CURSO`, `ENTREGADO`, `CALIFICADO` |
| Motivo de entrega | `MANUAL`, `VENCIMIENTO` |

- `max_intentos = NULL`: sin límite de cantidad; cero no es válido.
- `duracion_minutos = NULL`: sin límite de duración propio; el cierre de disponibilidad puede limitar igualmente el intento.
- `disponible_hasta = NULL`: sin cierre definido por la actividad.
- `vence_en = NULL`: ese intento no tiene un vencimiento calculado.
- Puntaje `NULL`: todavía no calificado; no convertirlo a cero.
- Respuesta sin filas en `respuesta_opciones`: pregunta sin contestar.
- `p_opciones = ARRAY[]::INTEGER[]`: limpiar selección. `NULL` o elementos `NULL` son inválidos.

## 6. Operaciones que debe utilizar el backend

Las firmas siguientes son las existentes. Los parámetros con estudiante ID deben proceder de la sesión verificada por Express. Los permisos SQL no autentican al usuario final cuando todas las solicitudes comparten una cuenta de conexión.

### 6.1 Iniciar

```sql
SELECT public.iniciar_intento($1, $2, $3) AS intento_id;
-- $1 actividad_id; $2 inscripcion_id; $3 estudiante autenticado
```

Devuelve un entero. Comprueba existencia y propiedad, cuenta y rol estudiante activos, inscripción activa, sección coincidente, actividad publicada, disponibilidad, ausencia de otro intento abierto y límite de intentos.

Numera el intento, copia el puntaje máximo, calcula vencimiento y crea una respuesta vacía por pregunta. Todo ocurre dentro de la misma llamada. No insertar respuestas vacías otra vez desde Node.

Bloquea la actividad y la inscripción. La actividad se usa como punto común de coordinación con la edición de preguntas. Mantener transacciones breves; no esperar la respuesta de Python o una llamada de red dentro de esos bloqueos.

La duración se cuenta desde el inicio; el vencimiento es el menor entre esa duración y `disponible_hasta`. La disponibilidad comienza inclusivamente y termina cuando `ahora >= disponible_hasta`.

**No comprueba todavía** el calendario/estado completo de edición y sección, publicación del módulo/tema ni incompatibilidad docente–estudiante. Un intento vencido que siga abierto bloquea otro hasta procesar su entrega.

### 6.2 Guardar o reemplazar selecciones

```sql
SELECT public.guardar_opciones_respuesta($1, $2, $3::INTEGER[]);
-- $1 respuesta_id; $2 estudiante autenticado; $3 lista completa de opcion_id
```

Retorna `VOID`. Cada llamada reemplaza toda la selección anterior de esa respuesta. El frontend debe enviar un arreglo de IDs, no letras, textos, puntajes ni el campo `es_correcta`.

Valida propiedad, cuenta/rol activos, intento en curso, respuesta sin calificar, plazo, opciones pertenecientes a la pregunta, ausencia de repetidos/NULL y máximo de una selección para selección única.

Para selección múltiple se permite guardar una selección incompleta; eso no implica que sea correcta. La calificación se realiza después de entregar.

### 6.3 Entregar

```sql
SELECT * FROM public.entregar_intento($1, $2);
-- $1 intento_id; $2 estudiante autenticado
```

Retorna la fila del intento. Comprueba propiedad, cuenta y rol activos. Cierra como `ENTREGADO`, sin puntajes. Si ya venció, utiliza `VENCIMIENTO`; de lo contrario, `MANUAL`.

La fecha de entrega registra cuándo se procesó el cierre, no necesariamente la hora exacta del vencimiento. El plazo continúa en `vence_en`.

Puede entregar preguntas vacías, pero no acepta que falten sus registros de respuesta. Si ya está entregado o calificado, devuelve lo existente sin cambiar fechas, después de las comprobaciones de identidad y cuenta.

No vuelve a exigir sección actual coincidente ni actividad publicada: los cambios administrativos posteriores no deben impedir cerrar el trabajo iniciado.

**No es un proceso automático:** necesita una llamada. El cierre de intentos abandonados sigue pendiente.

### 6.4 Calificar

```sql
SELECT * FROM public.calificar_intento($1);
-- $1 intento_id; uso interno del servidor
```

Retorna la fila del intento. Solo califica `ENTREGADO`; repetir sobre `CALIFICADO` devuelve el resultado anterior. No exige que el estudiante siga activo.

Por pregunta: conjunto seleccionado exactamente igual al correcto → puntaje máximo; cualquier otra combinación o respuesta vacía → cero. No hay puntuación parcial. Suma las respuestas y cambia a `CALIFICADO`.

Node no calcula ni envía puntajes. Express debe controlar cuándo permite iniciar esta operación y no aceptar un intento arbitrario de otro estudiante desde una ruta pública.

### 6.5 Transacciones y errores

Las cuatro funciones adquieren bloqueos según la operación. Utilizar el mismo cliente obtenido de `pool.connect()` si Node envuelve varias consultas en una transacción; no distribuir `BEGIN` y consultas entre conexiones aleatorias del pool.

| SQLSTATE | Interpretación para el servicio |
|---|---|
| `P0001` | Excepción de negocio lanzada por estas funciones. Varias causas comparten el código; todavía no hay códigos estables por cada regla. |
| `23505` | Unicidad violada; identificar la restricción antes de decidir la respuesta. |
| `23503` | Referencia inexistente o incompatible. |
| `23514` | Restricción CHECK violada. |
| `42501` | Permiso insuficiente: revisar integración/configuración. |
| `40P01` / `40001` | Deadlock o fallo de serialización: rollback y política de reintento acotada de la transacción completa. |

El mapeo HTTP definitivo pertenece al backend. No asumir que todo `P0001` es un 400 ni devolver SQL, trazas o detalles internos al cliente. Los textos actuales explican reglas, pero no son un contrato estable de códigos de API.

## 7. Consulta de resultados

La vista `public.resultados_actividades` devuelve:

`actividad_id`, `titulo`, `seccion_id`, `tema_id`, `finalidad`, `metodo_calificacion`, `inscripcion_id`, `estudiante_id`, `intentos_iniciados`, `intentos_en_curso`, `intentos_pendientes_calificacion`, `intentos_calificados`, `promedio_porcentaje`, `nota_academica_porcentaje`.

```sql
SELECT actividad_id, titulo, finalidad,
       intentos_calificados, promedio_porcentaje, nota_academica_porcentaje
FROM public.resultados_actividades
WHERE estudiante_id = $1 AND inscripcion_id = $2
ORDER BY actividad_id;
```

El backend valida que el usuario puede consultar esa inscripción. La vista no aplica autorización por sí sola y no hay RLS.

- Solo promedia intentos calificados: `AVG(puntaje_obtenido * 100 / puntaje_maximo)`.
- Se redondea el promedio final a dos decimales.
- Sin calificados: promedio `NULL`. Sin ningún intento: no hay fila en la vista.
- Práctica: muestra promedio, pero nota académica `NULL`.
- Evaluación: nota académica de la actividad igual al promedio.
- No hay ponderaciones ni nota final del curso implementadas.
- Los resultados no equivalen a progreso o finalización de un tema.

## 8. Triggers: qué hacen y qué no debe duplicarse

| Trigger | Función ejecutada | Efecto |
|---|---|---|
| `trg_validar_curso_actividad` | `validar_curso_actividad()` | Antes de insertar o cambiar sección/tema, exige que pertenezcan al mismo curso. |
| `trg_ediciones_curso_padre_inmutable` | `impedir_cambio_padre_academico('curso_id')` | Impide mover la edición a otro curso. |
| `trg_secciones_padre_inmutable` | `impedir_cambio_padre_academico('edicion_id')` | Impide mover la sección a otra edición. |
| `trg_modulos_padre_inmutable` | `impedir_cambio_padre_academico('curso_id')` | Impide mover el módulo a otro curso. |
| `trg_temas_padre_inmutable` | `impedir_cambio_padre_academico('modulo_id')` | Impide mover el tema a otro módulo. |
| `trg_proteger_preguntas_actividad` | `proteger_preguntas_actividad()` | Solo inserta/actualiza/elimina preguntas en borrador y sin intentos; impide trasladarlas. |
| `trg_proteger_opciones_actividad` | `proteger_opciones_actividad()` | Misma protección para opciones; impide cambiar su pregunta. |
| `trg_validar_publicacion_actividad` | `validar_publicacion_actividad()` | Publicación con preguntas y opciones válidas. |
| `trg_proteger_actividad_con_intentos` | `proteger_actividad_con_intentos()` | Con intentos, no volver a borrador ni cambiar condiciones o datos de creación. |

Las seis funciones anteriores devuelven `TRIGGER`; no se llaman como endpoints ni mediante `SELECT` para ejecutar operaciones de usuario. PostgreSQL las activa automáticamente.

Publicar exige una pregunta como mínimo, dos opciones por pregunta, una correcta en única y al menos dos correctas en múltiple. No se exige una incorrecta en múltiple. Crear en borrador, cargar preguntas/opciones y después publicar.

Con intentos existentes se preservan sección, tema, título, instrucciones, finalidad, método, límites, disponibilidad y autor/fecha de creación. Se permite archivar. Para una revisión sustancial, crear otra actividad; no existe versionado formal.

Archivar impide nuevos inicios mediante la función. No cierra intentos existentes. Los triggers no programan tareas al pasar el tiempo ni actualizan automáticamente todas las fechas de modificación.

El backend puede validar antes para explicar mejor los errores, pero no debe debilitar estas protecciones ni sustituirlas por validación exclusiva del frontend.

## 9. Permisos y operación administrativa

| Cuenta | Contrato de acceso |
|---|---|
| `postgres` | Instala y administra; no es la conexión ordinaria de la aplicación. |
| `plataforma_backend` | Lecturas concedidas, registro actual por columnas y ejecución de cuatro funciones. Sin escritura directa en resultados. |
| `plataforma_operaciones` | NOLOGIN; ejecuta las funciones SECURITY DEFINER con permisos internos limitados. |

Las cuatro funciones usan `search_path=pg_catalog, public, pg_temp`, no se ejecutan por PUBLIC y pertenecen a `plataforma_operaciones`. El backend no es miembro del rol interno. No modificar propietarios ni conceder membresías para resolver errores.

El backend no puede leer directamente `opciones_respuestas.es_correcta`. Sí puede leer `preguntas.explicacion`: el servicio debe decidir cuándo la expone. También puede leer datos de usuarios para autenticar; nunca serializar `password_hash`.

El registro público actual inserta usuario y asignación en una transacción, fija ESTUDIANTE y usa el propio usuario en `asignado_por`. El permiso SQL de inserción de asignaciones no garantiza por sí mismo que solo pueda elegirse ese rol: la encapsulación del registro sigue pendiente.

No se han concedido escrituras para que Express administre cursos, módulos o actividades. Esas interfaces requieren operaciones y permisos específicos acordados; no usar un grant general sobre todas las tablas.

El orden de instalación es 001 → 002 → 003 → seguridad. Al reemplazar una función operativa conservar SECURITY DEFINER y search_path o reaplicar su configuración. El merge de Git no ejecuta SQL ni configura contraseñas.

## 10. Contrato actual del motor Python y brecha de datos

Esta sección refleja los archivos `analyzer.py` y `adaptation_rules.py` recibidos. Verificar que no hayan cambiado antes de integrarlos. No implica que exista un adaptador PostgreSQL→Python.

`analyze_behavior(student_data)` recibe `student_id`, `topic` y una lista no vacía `interactions`. Todos sus registros deben aportar los seis campos siguientes, convertibles a números:

| Campo de entrada | Validación y uso actuales | Disponibilidad en PostgreSQL |
|---|---|---|
| `study_minutes` | >= 0; promedio en el perfil. | No se registra tiempo activo. Duración entre inicio y entrega no demuestra estudio efectivo. |
| `errors` | >= 0; suma en el perfil. | No hay columna equivalente. Se puede proponer contar preguntas con cero, distinguiendo incorrectas/vacías según el acuerdo futuro. |
| `attempts` | >= 1; promedio en el perfil. | Existen intentos, pero falta acordar la unidad del registro y la agregación. `numero_intento` no es automáticamente la métrica. |
| `repetitions` | >= 0; suma en el perfil. | Sin captura ni almacenamiento actuales. |
| `navigation_count` | >= 0; obligatorio, aunque no se devuelve agregado ni influye en las reglas actuales. | Sin captura ni almacenamiento actuales. |
| `score_percentage` | Entre 0 y 100; promedio en el perfil. | Derivable de un intento calificado o de la vista, pero son unidades distintas; elegir una explícitamente. |

No enviar toda la historia de un usuario mezclando temas o ediciones bajo un solo `topic`. La propuesta es trabajar por inscripción y tema; la ventana de hasta cinco registros aún no está implementada ni acordada como regla definitiva.

El analizador devuelve `student_id`, `topic`, `average_score`, `total_errors`, `average_attempts`, `total_repetitions`, `average_study_minutes` y `total_interactions`.

`generate_recommendation(profile)` devuelve `student_id`, `topic`, `action`, `difficulty`, `reason` y `recommendation`. Sus reglas, en ese orden, son:

| Condición actual | Acción / dificultad |
|---|---|
| Promedio < 60 o errores acumulados >= 5 | `reinforce_topic` / `reduced` |
| En caso contrario: promedio >= 85, errores <= 2 e intentos promedio <= 2 | `increase_difficulty` / `increased` |
| Resto | `maintain_difficulty` / `current` |

Si hay al menos cinco repeticiones y la acción es refuerzo, añade una sugerencia de material alternativo. Los umbrales dependen de la cantidad y significado de los registros; no cambiar la ventana sin revisar ese efecto.

**Brecha que debe resolverse antes de usar datos reales:** unidad de interacción, agregación de intentos/errores, captura de métricas faltantes, caso sin datos y almacenamiento de recomendaciones. El código actual rechaza ausencia de interacciones y métricas nulas. No resolverlo enviando ceros inventados ni creando otra tabla de usuarios/temas.

Una traducción de nombres españoles a claves JSON inglesas pertenece al adaptador de Node. Python recibe datos mediante su contrato; no necesita credenciales administrativas ni escribir notas académicas. Una recomendación no modifica automáticamente la nota o la dificultad de una actividad usada.

## 11. Cambios que requieren coordinación

No está terminado lo siguiente: RLS, cupos concurrentes, cambio de sección e historial, incompatibilidad docente–estudiante, administración académica desde Express, contenidos, progreso, interacciones, recomendaciones, cierre automático, pruebas entre sesiones y autenticación HTTP del nuevo rol.

El backend revisado todavía selecciona un rol mediante LIMIT 1 y busca el correo mediante JOIN con roles activos. El esquema admite varios roles y usuarios sin asignación activa. Coordinar su corrección; no reducir el modelo a un rol para acomodar esas consultas.

Si una parte requiere una capacidad nueva:

1. Describir el caso y los datos que faltan.
2. Comprobar si se resuelve con una consulta/adaptador sobre lo existente.
3. Si requiere SQL nuevo, acordar nombres, relaciones, permisos y contrato de entrada/salida.
4. Crear migración incremental y pruebas; revisar el impacto en consumidores.
5. Actualizar este contrato y README en el mismo pull request.

No interpretar una propuesta futura como una garantía implementada.

## 12. Referencia rápida para entregar a un agente

> Trabaja con el contrato `database/docs/CONTRATO_INTEGRACION_BD.md` y verifica las migraciones 001–003 y el script de seguridad antes de cambiar código. Integra mediante las funciones existentes; no renombres ni dupliques tablas. Mantén el estudiante autenticado como fuente de identidad, separa notas de recomendaciones y no inventes métricas faltantes. Si encuentras una necesidad no cubierta, identifica la brecha y propone un cambio separado para revisión, sin modificar silenciosamente el esquema ni sus permisos. Indica qué verificaste y qué sigue pendiente.
