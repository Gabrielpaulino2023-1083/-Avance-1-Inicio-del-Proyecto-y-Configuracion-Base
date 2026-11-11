# Contrato de integración de la base de datos

Referencia: **BD-005-v1** · Actualizado: **10 de noviembre de 2026**.

Lecturas complementarias: [diccionario de datos](DICCIONARIO_DATOS_BD.md), [operaciones de cursos](CRUD_CURSOS_AVANCE_3.md) y [evidencias](../test/RESULTADO_VALIDACION_005.md).

Destinatarios: responsables de backend, motor adaptativo, frontend, QA y agentes de IA que colaboren con ellos.

Este documento describe el comportamiento existente para integrar los módulos sin inventar tablas, columnas, permisos o reglas. El README contiene la instalación y el historial de verificaciones; este contrato contiene las decisiones que una implementación debe respetar.
## 1. Alcance y autoridad
La referencia de esta versión son los archivos:
- database/migrations/001_estructura_academica_inicial.sql
- database/migrations/002_modulos_temas.sql
- database/migrations/003_actividades_intentos_respuestas.sql corregida
- database/security/001_roles_permisos.sql corregido
- database/migrations/004_inscripcion_estudiantes.sql
- database/migrations/005_crud_cursos.sql
- database/seeds/datos_prueba_administrador.sql
- database/seeds/datos_prueba_actividades_intentos.sql (datos de integración)
Después de 005: 17 tablas, una vista, 17 funciones propias y nueve triggers. Diez funciones son operativas, seis son de trigger y una es auxiliar privada. La instalación completa desde cero y las pruebas de 003–005 pasaron en PGlite. El responsable confirmó además la ejecución de 005 y sus pruebas en PostgreSQL local, el seed administrativo y login/me de administrador y estudiante tras configurar DB_USER=plataforma_backend. No se inspeccionó el pool del proceso para certificar current_user; no se afirma integración HTTP de cursos por estas pruebas de autenticación.

001–004 están publicadas en main; 005 y esta documentación están preparadas para PR. El merge no aplica migraciones en las bases del equipo. La evidencia distingue pruebas automatizadas, resultados locales reportados e integración pendiente.

Las migraciones definen lo que existe; los permisos definen lo que la cuenta de conexión puede hacer; este contrato explica cómo usarlo. Ante una discrepancia, revisar las fuentes y acordar la corrección, no modificar el esquema por una suposición. La ejecución completa del archivo consolidado de regresión fue confirmada por el responsable de base de datos; los casos incluidos finalizaron con el resultado esperado.

No se busca impedir toda evolución. Una necesidad no cubierta se presenta como un cambio explícito, separado y revisable, sin alterar silenciosamente contratos ya utilizados.
## 2. Instrucciones para desarrolladores y agentes de IA
1. Leer este contrato y las migraciones antes de escribir consultas o modelos.
2. Mantener los nombres SQL existentes. Los nombres del JSON pueden adaptarse en el servicio sin renombrar tablas.
3. Usar las funciones operativas para administrar cursos, inscribir, iniciar, guardar, entregar y calificar. No reemplazarlas por inserciones o actualizaciones directas.
4. No agregar tablas users, topics, interactions o recommendations suponiendo que ya forman parte del esquema. usuarios y temas ya existen; interacciones y recomendaciones todavía no.
5. No conceder privilegios para hacer desaparecer un error de permisos. Verificar primero si se está omitiendo la operación controlada.
6. No utilizar postgres como conexión habitual de Express ni guardar credenciales reales en el repositorio.
7. Obtener el estudiante desde la identidad autenticada. No confiar en estudiante_id proporcionado libremente por el navegador.
8. No devolver hashes, claves correctas ni explicaciones que revelen respuestas antes del momento autorizado. No devolver automáticamente todas las columnas de una consulta.
9. No afirmar que un endpoint existe porque este documento contiene una consulta. Este contrato no crea rutas HTTP ni fija sus DTOs.
10. Ante un dato ausente, explicar la carencia. No fabricar métricas o guardar ceros para hacer pasar una validación del motor.
11. No editar migraciones ya adoptadas para actualizar bases existentes. Proponer una migración incremental y revisar compatibilidad.
12. Documentar qué se probó y qué sigue pendiente. No equiparar pruebas SQL locales con integración completa.
## 3. Mapa de entidades
- Organización académica: cursos → ediciones_curso → secciones → inscripciones.
- Estructura educativa: cursos → modulos → temas.
- Actividad: una sección y un tema del mismo curso.
- Evaluación de resultados: actividades → preguntas → opciones_respuestas.
- Participación: inscripciones → intentos → respuestas → respuesta_opciones.
Un rol permite una función general; la asignación determina dónde se ejerce. Tener rol docente no autoriza a editar todos los cursos. curso_editores autoriza edición compartida y seccion_docentes identifica responsables de sección; su autorización completa sigue pendiente en los servicios.

El esquema permite varios roles activos. La política de incompatibilidad estudiante/docente requiere confirmación del equipo: se discutieron la desactivación previa del rol estudiante y restricciones por sección. No se implementa ninguna de esas incompatibilidades en 004. No presentarlas como una garantía ni resolver esa decisión cambiando el esquema unilateralmente.

Una inscripción representa al estudiante en una edición. No crear otra inscripción al cambiarlo de sección: la operación de traslado e historial está pendiente. Los intentos anteriores conservan su actividad original.
## 4. Diccionario de tablas existentes
Todos los nombres pertenecen al esquema public. Salvo respuesta_opciones, las tablas tienen id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY. No suponer IDs fijos ni secuencias sin huecos.

| Tabla | Columnas adicionales a id |
| --- | --- |
| usuarios | nombre, apellido, email, password_hash, activo, creado_en, actualizado_en |
| roles | codigo, nombre |
| usuario_roles | usuario_id, rol_id, activo, asignado_por, asignado_en, desactivado_en |
| cursos | codigo, nombre, descripcion, estado, creado_por, creado_en, actualizado_en |
| curso_editores | curso_id, usuario_id, activo, asignado_por, asignado_en |
| ediciones_curso | curso_id, codigo, nombre, fecha_inicio, fecha_fin, inscripcion_desde, inscripcion_hasta, estado, creado_por, creado_en |
| secciones | edicion_id, codigo, cupo_maximo, estado, creado_por, creado_en |
| seccion_docentes | seccion_id, usuario_id, activo, asignado_por, asignado_en |
| inscripciones | estudiante_id, edicion_id, seccion_id, estado, origen, registrado_por, inscrito_en, cerrado_en |
| modulos | curso_id, nombre, descripcion, orden, estado, creado_por, creado_en, actualizado_en |
| temas | modulo_id, nombre, descripcion, orden, estado, creado_por, creado_en, actualizado_en |
| actividades | seccion_id, tema_id, titulo, instrucciones, finalidad, metodo_calificacion, max_intentos, duracion_minutos, disponible_desde, disponible_hasta, estado, creado_por, creado_en, actualizado_en |
| preguntas | actividad_id, enunciado, tipo, orden, puntaje_maximo, explicacion |
| opciones_respuestas | pregunta_id, texto, orden, es_correcta |
| intentos | actividad_id, inscripcion_id, numero_intento, estado, iniciado_en, vence_en, entregado_en, motivo_entrega, calificado_en, puntaje_obtenido, puntaje_maximo |
| respuestas | intento_id, pregunta_id, actividad_id, creado_en, actualizado_en, calificado_en, puntaje_obtenido |
| respuesta_opciones | Sin id: respuesta_id, pregunta_id, opcion_id; clave primaria (respuesta_id, opcion_id) |



Reglas transversales:
- Correo único sobre lower(email) y sin espacios exteriores. Los textos obligatorios no admiten cadena vacía ni solo espacios.
- Puntajes NUMERIC(10,2). Mantener cálculos decimales; el backend debe comprobar cómo pg representa NUMERIC antes de serializar JSON. No asumir que siempre llega como número JavaScript.
- Fechas de tipo TIMESTAMPTZ. Usar fechas con zona explícita; para el navegador se recomienda ISO 8601 con zona. No comparar cadenas de fecha locales.
- Orden entero desde 1, único por padre. Los nombres no son claves únicas.
- Código de edición único por curso y código de sección único por edición.
- Una inscripción por estudiante y edición, incluso si está cerrada.
- ON DELETE RESTRICT protege referencias; no representa una política completa de borrado lógico para todas las tablas.
- Los valores predeterminados de actualizado_en no crean una actualización automática general.
## 5. Valores y significado de NULL

| Campo o entidad | Valores |
| --- | --- |
| roles.codigo | ESTUDIANTE, DOCENTE, ADMINISTRADOR |
| Curso | BORRADOR, ACTIVO, ARCHIVADO |
| Edición | PLANIFICADA, ABIERTA, EN_CURSO, FINALIZADA, CANCELADA |
| Sección | ABIERTA, CERRADA, CANCELADA |
| Inscripción | ACTIVA, RETIRADA, COMPLETADA, CANCELADA |
| inscripciones.origen | AUTONOMA, ADMINISTRATIVA |
| Módulo, tema, actividad | BORRADOR, PUBLICADO, ARCHIVADO |
| actividades.finalidad | PRACTICA, EVALUACION |
| actividades.metodo_calificacion | Solo PROMEDIO |
| preguntas.tipo | SELECCION_UNICA, SELECCION_MULTIPLE |
| Intento | EN_CURSO, ENTREGADO, CALIFICADO |
| Motivo de entrega | MANUAL, VENCIMIENTO |



- max_intentos = NULL: sin límite de cantidad; cero no es válido.
- duracion_minutos = NULL: sin límite de duración propio; el cierre de disponibilidad puede limitar igualmente el intento.
- disponible_hasta = NULL: sin cierre definido por la actividad.
- vence_en = NULL: ese intento no tiene un vencimiento calculado.
- Puntaje NULL: todavía no calificado; no convertirlo a cero.
- Respuesta sin filas en respuesta_opciones: pregunta sin contestar.
- p_opciones = ARRAY[]::INTEGER[]: limpiar selección. NULL o elementos NULL son inválidos.
## 6. Operaciones que debe utilizar el backend
Las firmas siguientes son las existentes. Los parámetros con estudiante ID deben proceder de la sesión verificada por Express. Los permisos SQL no autentican al usuario final cuando todas las solicitudes comparten una cuenta de conexión.
### 6.0 Administración de cursos — disponible desde 005

Las cinco funciones y sus firmas, transiciones, permisos y ejemplos están en [CRUD_CURSOS_AVANCE_3.md](CRUD_CURSOS_AVANCE_3.md). El actor es el ID autenticado y se exige cuenta/asignación ADMINISTRADOR activa. La auxiliar validar_administrador_cursos(INTEGER) es privada y no se llama desde Express.

- crear_curso_admin(INTEGER, TEXT, TEXT, TEXT): actor, código, nombre, descripción; crea BORRADOR.
- listar_cursos_admin(INTEGER, TEXT, INTEGER, INTEGER): actor, estado o NULL, límite, desplazamiento; devuelve un conjunto de cursos.
- obtener_curso_admin(INTEGER, INTEGER): actor, curso; devuelve una fila.
- actualizar_curso_admin(INTEGER, INTEGER, TEXT, TEXT, TEXT): actor, curso y los tres campos completos; no permite editar ARCHIVADO.
- cambiar_estado_curso_admin(INTEGER, INTEGER, TEXT): actor, curso, ACTIVO o ARCHIVADO. Sin regreso a BORRADOR ni reactivación. Repetir el estado actual conserva fecha.

Todas devuelven cursos; solo el listado devuelve varias filas. La baja es lógica. Archivar rechaza ediciones PLANIFICADA, ABIERTA o EN_CURSO y conserva el historial. No existe escritura administrativa directa de Express sobre cursos ni CRUD HTTP implementado por la migración.

### 6.1 Inscribir un estudiante — disponible desde 004
SELECT * FROM public.inscribir_estudiante($1, $2, $3);
-- $1 seccion_id; $2 estudiante_id; $3 actor_id autenticado
Firma exacta: public.inscribir_estudiante(INTEGER, INTEGER, INTEGER) RETURNS public.inscripciones. Devuelve id, estudiante_id, edicion_id, seccion_id, estado, origen, registrado_por, inscrito_en y cerrado_en. No recibir edición, origen, estado ni fecha desde el cliente para esta operación.

| Regla | Comportamiento de la función |
| --- | --- |
| Identidad | Actor y estudiante existen y tienen cuenta activa; estudiante con rol ESTUDIANTE activo. |
| Operación propia | Actor igual al estudiante: AUTONOMA, incluso si también es administrador. |
| Operación sobre otro | Requiere ADMINISTRADOR activo del actor: ADMINISTRATIVA. |
| Organización | Curso ACTIVO, edición ABIERTA, sección ABIERTA. |
| Calendario | inscripcion_desde <= reloj actual < inscripcion_hasta; ambos extremos configurados. Se verifica tras adquirir bloqueos. No añade una condición independiente sobre fecha_inicio. |
| Duplicados | Rechaza inscripción existente del estudiante en esa edición en cualquier estado. No reactiva ni traslada. |
| Cupo | Cuenta inscripciones ACTIVA de la sección y exige cantidad menor que cupo_maximo. Sin excepciones para administradores. |
| Concurrencia | Bloquea curso/edición, sección, cuentas y asignaciones. Sección es el punto de coordinación del cupo. Requiere READ COMMITTED; prueba entre sesiones pendiente. |
| Resultado | Inserta ACTIVA, origen determinado, actor como registrado_por, reloj como inscrito_en y cerrado_en NULL. |



La FK compuesta y UNIQUE(estudiante_id, edicion_id) siguen protegiendo integridad. Dos solicitudes a distintas secciones de una edición pueden terminar en 23505; el backend debe tratar esa restricción como conflicto y no intentar insertar directamente. La función no es idempotente: repetir tras una inscripción confirmada produce rechazo por duplicado.

Ejemplo de servicio Node con consultas parametrizadas:
// actorId procede del middleware que verifica el token.
// En autoservicio, estudianteId = actorId.
// En la ruta administrativa, autorizar al actor antes de llamar.
const { rows } = await pool.query(
  'SELECT * FROM public.inscribir_estudiante($1, $2, $3)',
  [seccionId, estudianteId, actorId]
);
return rows[0];
Validar enteros y acceso en el backend. No aceptar actorId del body, no confiar solo en el rol enviado por el cliente y no cambiar la conexión a postgres. La función comprueba asignaciones actuales en BD, pero no valida JWT: una conexión compartida confía en la identidad que le suministra el servidor. Ninguna ruta de inscripción HTTP se declara implementada por este ejemplo.

La 004 concede EXECUTE al backend y permisos internos al propietario NOLOGIN, no INSERT directo en inscripciones. Hay que aplicar sus GRANT además de crear la función. Para READ COMMITTED y transacciones explícitas usar el mismo cliente del pool y finalizar con COMMIT/ROLLBACK; no esperar una llamada al motor mientras se mantienen bloqueos.

Las garantías de cupo dependen de utilizar esta vía y de coordinar futuras modificaciones de cupo, reactivaciones y traslados. No se implementó un trigger universal para escrituras de administradores SQL.
### 6.2 Iniciar
SELECT public.iniciar_intento($1, $2, $3) AS intento_id;
-- $1 actividad_id; $2 inscripcion_id; $3 estudiante autenticado
Devuelve un entero. Comprueba existencia y propiedad, cuenta y rol estudiante activos, inscripción activa, sección coincidente, actividad publicada, disponibilidad, ausencia de otro intento abierto y límite de intentos.

Numera el intento, copia el puntaje máximo, calcula vencimiento y crea una respuesta vacía por pregunta. Todo ocurre dentro de la misma llamada. No insertar respuestas vacías otra vez desde Node.

Bloquea la actividad y la inscripción. La actividad se usa como punto común de coordinación con la edición de preguntas. Mantener transacciones breves; no esperar la respuesta de Python o una llamada de red dentro de esos bloqueos.

La duración se cuenta desde el inicio; el vencimiento es el menor entre esa duración y disponible_hasta. La disponibilidad comienza inclusivamente y termina cuando ahora >= disponible_hasta.

No comprueba todavía el calendario/estado completo de edición y sección, publicación del módulo/tema ni incompatibilidad docente–estudiante. Un intento vencido que siga abierto bloquea otro hasta procesar su entrega.
### 6.3 Guardar o reemplazar selecciones
SELECT public.guardar_opciones_respuesta($1, $2, $3::INTEGER[]);
-- $1 respuesta_id; $2 estudiante autenticado; $3 lista completa de opcion_id
Retorna VOID. Cada llamada reemplaza toda la selección anterior de esa respuesta. El frontend debe enviar un arreglo de IDs, no letras, textos, puntajes ni el campo es_correcta.

Valida propiedad, cuenta/rol activos, intento en curso, respuesta sin calificar, plazo, opciones pertenecientes a la pregunta, ausencia de repetidos/NULL y máximo de una selección para selección única.

Para selección múltiple se permite guardar una selección incompleta; eso no implica que sea correcta. La calificación se realiza después de entregar.
### 6.4 Entregar
SELECT * FROM public.entregar_intento($1, $2);
-- $1 intento_id; $2 estudiante autenticado
Retorna la fila del intento. Comprueba propiedad, cuenta y rol activos. Cierra como ENTREGADO, sin puntajes. Si ya venció, utiliza VENCIMIENTO; de lo contrario, MANUAL.

La fecha de entrega registra cuándo se procesó el cierre, no necesariamente la hora exacta del vencimiento. El plazo continúa en vence_en.

Puede entregar preguntas vacías, pero no acepta que falten sus registros de respuesta. Si ya está entregado o calificado, devuelve lo existente sin cambiar fechas, después de las comprobaciones de identidad y cuenta.

No vuelve a exigir sección actual coincidente ni actividad publicada: los cambios administrativos posteriores no deben impedir cerrar el trabajo iniciado.

No es un proceso automático: necesita una llamada. El cierre de intentos abandonados sigue pendiente.
### 6.5 Calificar
SELECT * FROM public.calificar_intento($1);
-- $1 intento_id; uso interno del servidor
Retorna la fila del intento. Solo califica ENTREGADO; repetir sobre CALIFICADO devuelve el resultado anterior. No exige que el estudiante siga activo.

Por pregunta: conjunto seleccionado exactamente igual al correcto → puntaje máximo; cualquier otra combinación o respuesta vacía → cero. No hay puntuación parcial. Suma las respuestas y cambia a CALIFICADO.

Node no calcula ni envía puntajes. Express debe controlar cuándo permite iniciar esta operación y no aceptar un intento arbitrario de otro estudiante desde una ruta pública.
### 6.6 Transacciones y errores
Las funciones operativas adquieren bloqueos según la operación. Los errores específicos de cursos se detallan en la guía de 005. Utilizar el mismo cliente obtenido de pool.connect() si Node envuelve varias consultas en una transacción; no distribuir BEGIN y consultas entre conexiones aleatorias del pool.

| SQLSTATE | Interpretación para el servicio |
| --- | --- |
| P0001 | Excepción de negocio lanzada por estas funciones. Varias causas comparten el código; todavía no hay códigos estables por cada regla. |
| 23505 | Unicidad violada; identificar la restricción antes de decidir la respuesta. |
| 23503 | Referencia inexistente o incompatible. |
| 23514 | Restricción CHECK violada. |
| 42501 | Permiso insuficiente: revisar integración/configuración. |
| 40P01 / 40001 | Deadlock o fallo de serialización: rollback y política de reintento acotada de la transacción completa. |



El mapeo HTTP definitivo pertenece al backend. No asumir que todo P0001 es un 400 ni devolver SQL, trazas o detalles internos al cliente. Los textos actuales explican reglas, pero no son un contrato estable de códigos de API.
## 7. Consulta de resultados
La vista public.resultados_actividades devuelve:

actividad_id, titulo, seccion_id, tema_id, finalidad, metodo_calificacion, inscripcion_id, estudiante_id, intentos_iniciados, intentos_en_curso, intentos_pendientes_calificacion, intentos_calificados, promedio_porcentaje, nota_academica_porcentaje.
SELECT actividad_id, titulo, finalidad,
       intentos_calificados, promedio_porcentaje, nota_academica_porcentaje
FROM public.resultados_actividades
WHERE estudiante_id = $1 AND inscripcion_id = $2
ORDER BY actividad_id;
El backend valida que el usuario puede consultar esa inscripción. La vista no aplica autorización por sí sola y no hay RLS.
- Solo promedia intentos calificados: AVG(puntaje_obtenido * 100 / puntaje_maximo).
- Se redondea el promedio final a dos decimales.
- Sin calificados: promedio NULL. Sin ningún intento: no hay fila en la vista.
- Práctica: muestra promedio, pero nota académica NULL.
- Evaluación: nota académica de la actividad igual al promedio.
- No hay ponderaciones ni nota final del curso implementadas.
- Los resultados no equivalen a progreso o finalización de un tema.
## 8. Triggers: qué hacen y qué no debe duplicarse

| Trigger | Función ejecutada | Efecto |
| --- | --- | --- |
| trg_validar_curso_actividad | validar_curso_actividad() | Antes de insertar o cambiar sección/tema, exige que pertenezcan al mismo curso. |
| trg_ediciones_curso_padre_inmutable | impedir_cambio_padre_academico('curso_id') | Impide mover la edición a otro curso. |
| trg_secciones_padre_inmutable | impedir_cambio_padre_academico('edicion_id') | Impide mover la sección a otra edición. |
| trg_modulos_padre_inmutable | impedir_cambio_padre_academico('curso_id') | Impide mover el módulo a otro curso. |
| trg_temas_padre_inmutable | impedir_cambio_padre_academico('modulo_id') | Impide mover el tema a otro módulo. |
| trg_proteger_preguntas_actividad | proteger_preguntas_actividad() | Solo inserta/actualiza/elimina preguntas en borrador y sin intentos; impide trasladarlas. |
| trg_proteger_opciones_actividad | proteger_opciones_actividad() | Misma protección para opciones; impide cambiar su pregunta. |
| trg_validar_publicacion_actividad | validar_publicacion_actividad() | Publicación con preguntas y opciones válidas. |
| trg_proteger_actividad_con_intentos | proteger_actividad_con_intentos() | Con intentos, no volver a borrador ni cambiar condiciones o datos de creación. |



Las seis funciones anteriores devuelven TRIGGER; no se llaman como endpoints ni mediante SELECT para ejecutar operaciones de usuario. PostgreSQL las activa automáticamente.

Publicar exige una pregunta como mínimo, dos opciones por pregunta, una correcta en única y al menos dos correctas en múltiple. No se exige una incorrecta en múltiple. Crear en borrador, cargar preguntas/opciones y después publicar.

Con intentos existentes se preservan sección, tema, título, instrucciones, finalidad, método, límites, disponibilidad y autor/fecha de creación. Se permite archivar. Para una revisión sustancial, crear otra actividad; no existe versionado formal.

Archivar impide nuevos inicios mediante la función. No cierra intentos existentes. Los triggers no programan tareas al pasar el tiempo ni actualizan automáticamente todas las fechas de modificación.

El backend puede validar antes para explicar mejor los errores, pero no debe debilitar estas protecciones ni sustituirlas por validación exclusiva del frontend.
## 9. Permisos y operación administrativa

| Cuenta | Contrato de acceso |
| --- | --- |
| postgres | Instala y administra; no es la conexión ordinaria de la aplicación. |
| plataforma_backend | Lecturas concedidas, registro actual por columnas y ejecución de diez funciones operativas. Sin escritura directa en resultados. |
| plataforma_operaciones | NOLOGIN; ejecuta las funciones SECURITY DEFINER con permisos internos limitados. |



Las diez funciones operativas y la auxiliar privada usan search_path=pg_catalog, public, pg_temp, no se ejecutan por PUBLIC y pertenecen a plataforma_operaciones. El backend no es miembro del rol interno. No modificar propietarios ni conceder membresías para resolver errores.

El backend no puede leer directamente opciones_respuestas.es_correcta. Sí puede leer preguntas.explicacion: el servicio debe decidir cuándo la expone. También puede leer datos de usuarios para autenticar; nunca serializar password_hash.

El registro público actual inserta usuario y asignación en una transacción, fija ESTUDIANTE y usa el propio usuario en asignado_por. El permiso SQL de inserción de asignaciones no garantiza por sí mismo que solo pueda elegirse ese rol: la encapsulación del registro sigue pendiente.

005 permite administrar cursos mediante funciones; módulos y actividades siguen sin operaciones administrativas concedidas. Esas interfaces requieren operaciones y permisos específicos acordados; no usar un grant general sobre todas las tablas.

El orden de instalación es 001 → 002 → 003 → seguridad → 004 → 005. La 004 depende de plataforma_operaciones y plataforma_backend; no basta ejecutar migrations en orden alfabético antes de crear esos roles. Al reemplazar una función operativa conservar SECURITY DEFINER y search_path o reaplicar su configuración. El merge de Git no ejecuta SQL ni configura contraseñas.
## 10. Contrato actual del motor Python y brecha de datos
Referencia histórica, no requisito de crear tablas nuevas: esta sección refleja los archivos analyzer.py y adaptation_rules.py recibidos anteriormente. El responsable del backend indicó después que intentos, respuestas y resultados_actividades permiten sustituir gran parte de los datos simulados y que no necesita una tabla de interacciones por ahora. Verificar que no hayan cambiado antes de integrarlos. No implica que exista un adaptador PostgreSQL→Python.

analyze_behavior(student_data) recibe student_id, topic y una lista no vacía interactions. Todos sus registros deben aportar los seis campos siguientes, convertibles a números:

| Campo de entrada | Validación y uso actuales | Disponibilidad en PostgreSQL |
| --- | --- | --- |
| study_minutes | >= 0; promedio en el perfil. | No se registra tiempo activo. Duración entre inicio y entrega no demuestra estudio efectivo. |
| errors | >= 0; suma en el perfil. | No hay columna equivalente. Se puede proponer contar preguntas con cero, distinguiendo incorrectas/vacías según el acuerdo futuro. |
| attempts | >= 1; promedio en el perfil. | Existen intentos, pero falta acordar la unidad del registro y la agregación. numero_intento no es automáticamente la métrica. |
| repetitions | >= 0; suma en el perfil. | Sin captura ni almacenamiento actuales. |
| navigation_count | >= 0; obligatorio, aunque no se devuelve agregado ni influye en las reglas actuales. | Sin captura ni almacenamiento actuales. |
| score_percentage | Entre 0 y 100; promedio en el perfil. | Derivable de un intento calificado o de la vista, pero son unidades distintas; elegir una explícitamente. |



No enviar toda la historia de un usuario mezclando temas o ediciones bajo un solo topic. La propuesta es trabajar por inscripción y tema; la ventana de hasta cinco registros aún no está implementada ni acordada como regla definitiva.

El analizador devuelve student_id, topic, average_score, total_errors, average_attempts, total_repetitions, average_study_minutes y total_interactions.

generate_recommendation(profile) devuelve student_id, topic, action, difficulty, reason y recommendation. Sus reglas, en ese orden, son:

| Condición actual | Acción / dificultad |
| --- | --- |
| Promedio < 60 o errores acumulados >= 5 | reinforce_topic / reduced |
| En caso contrario: promedio >= 85, errores <= 2 e intentos promedio <= 2 | increase_difficulty / increased |
| Resto | maintain_difficulty / current |



Si hay al menos cinco repeticiones y la acción es refuerzo, añade una sugerencia de material alternativo. Los umbrales dependen de la cantidad y significado de los registros; no cambiar la ventana sin revisar ese efecto.

Brecha que debe resolverse antes de usar datos reales: unidad de interacción, agregación de intentos/errores, captura de métricas faltantes, caso sin datos y almacenamiento de recomendaciones. El código actual rechaza ausencia de interacciones y métricas nulas. No resolverlo enviando ceros inventados ni creando otra tabla de usuarios/temas.

Una traducción de nombres españoles a claves JSON inglesas pertenece al adaptador de Node. Python recibe datos mediante su contrato; no necesita credenciales administrativas ni escribir notas académicas. Una recomendación no modifica automáticamente la nota o la dificultad de una actividad usada.
## 11. Cambios que requieren coordinación
Estado de integración y próximos pasos:

| Área | Disponible / pendiente |
| --- | --- |
| Identidad demo | Login y /me probados para estudiante y administrador tras el cambio de configuración reportado; verificar el usuario efectivo del pool en cada entorno. |
| Inscripción | Función 004 y pruebas básicas SQL disponibles; endpoint HTTP y pruebas de fechas, estados y concurrencia pendientes. |
| Actividades | Cuatro funciones y vista disponibles; integrar endpoints autorizados y adaptador al motor. |
| Progreso | Propuesta próxima: vista por inscripción y tema, incluyendo temas sin intentos. No existe tabla ni vista de progreso todavía. |
| Finalización | Acordar actividades obligatorias, umbral y efecto de agregar actividades. Una tabla histórica solo si hay que conservar fecha/regla/evidencia de finalización. |
| Motor | Usar datos existentes; definir unidad de agregación y tratamiento de ausencia de datos. No inventar navegación, repeticiones ni tiempo activo. |
| Administración | Faltan operaciones/permisos de edición académica, retiro/reactivación/traslado, cambio seguro de cupos y asignaciones. |
| Otros | RLS, cierre automático, contenidos, recomendaciones persistentes y política de roles no implementados. No todos son requisitos del próximo entregable. |



Propuesta inicial de avance (aún no implementada ni regla académica definitiva): contar una actividad como realizada si tiene un intento calificado, aunque su nota sea cero. Diferenciar participación, aprobación y dominio estimado por el motor. No exponer una columna ficticia completado ni tratar publicación como finalización.

Prioridad del PR: publicar 005, seed administrativo, pruebas y documentación; integrar el CRUD de cursos con backend y frontend. Para completar la asignación semanal también quedan las consultas/métricas del motor y la evidencia conjunta. Progreso se pospone. No bloquear el backend esperando tablas especulativas de interacciones.

En la revisión anterior, el backend seleccionaba un rol mediante LIMIT 1 y busca el correo mediante JOIN con roles activos. El esquema admite varios roles y usuarios sin asignación activa. Coordinar su corrección; no reducir el modelo a un rol para acomodar esas consultas.

Si una parte requiere una capacidad nueva:
1. Describir el caso y los datos que faltan.
2. Comprobar si se resuelve con una consulta/adaptador sobre lo existente.
3. Si requiere SQL nuevo, acordar nombres, relaciones, permisos y contrato de entrada/salida.
4. Crear migración incremental y pruebas; revisar el impacto en consumidores.
5. Actualizar este contrato y README en el mismo pull request.
No interpretar una propuesta futura como una garantía implementada.
## 12. Datos de integración y evidencia
El seed database/seeds/datos_prueba_actividades_intentos.sql crea un curso independiente DEMO-003 y la cuenta estudiante.demo@example.com, activa y con rol ESTUDIANTE. Requiere administrador activo y catálogo de roles; no modifica las cuentas iniciales con hash ficticio. Ver README §4.5 para generar bcryptjs costo 10, ejecutar por archivo y proporcionar el hash. La contraseña sugerida DemoEquipo-2026! es pública y exclusiva de desarrollo. No confundirla con credenciales PostgreSQL o JWT_SECRET.

Datos: tres actividades publicadas con dos preguntas cada una (única y múltiple); práctica con dos intentos 0/20 y 20/20 y promedio 50; evaluación 20/20 y nota 100; práctica sin intentos para probar desde API. Permite más intentos, que alteran los promedios. Fechas relativas a creación, disponibilidad un año y duración 30 minutos. La tercera práctica no aparece aún en resultados_actividades; usar LEFT JOIN desde actividades y filtrar por inscripción autorizada para un listado completo.

El seed es transaccional y rechaza una cuenta/curso ya existentes. No es idempotente ni limpia datos. Cada entorno debe ejecutarlo; los IDs se consultan, no se fijan. Una cuenta compartida en una misma base comparte intentos; usar cuentas distintas para pruebas simultáneas. Este seed de actividades no crea administrador/docente ni asigna docentes. El seed separado datos_prueba_administrador.sql crea el administrador autenticable; la cuenta docente con login sigue pendiente si se necesita.

Guardar SQL como UTF-8 e incluir \encoding UTF8 antes de BEGIN del seed. Windows debe alinear consola y cliente; instrucciones en README. Las reparaciones locales de texto y suspensión de triggers fueron excepcionales, no parte del despliegue normal ni patrón para agentes.

| Evidencia reportada | Alcance |
| --- | --- |
| Seed confirmado por COMMIT | Resultados esperados 50 y 100, tercera actividad sin intentos. |
| POST /api/auth/login y GET /api/auth/me | Usuario demo autenticado y token aceptado; frontend no requerido. |
| SET LOCAL ROLE plataforma_backend | Sin INSERT sobre estudiante_id; con EXECUTE de inscribir_estudiante. No es prueba de login TCP del rol SQL. |
| Inscripción propia | ACTIVA/AUTONOMA; duplicado rechazado. |
| Inscripción de otro | Estudiante rechazado, administrador permitido con origen ADMINISTRATIVA. |
| Cupo secuencial | Administrador rechazado al intentar superar cupo uno; una ACTIVA. |



Las pruebas consolidadas de database/test/pruebas_migracion_004.sql se ejecutaron satisfactoriamente en PostgreSQL local. Se verificaron permisos, inscripción autónoma y administrativa, duplicados, actor no autorizado y cupo lleno. Las pruebas de fechas, estados, cuentas/roles inactivos y concurrencia entre sesiones siguen pendientes.
## 13. Referencia rápida para entregar a un agente
Trabaja con el contrato database/docs/CONTRATO_INTEGRACION_BD.md y verifica las migraciones 001–005, el seed de integración y el script de seguridad antes de cambiar código. Integra mediante las funciones existentes; no renombres ni dupliques tablas. Mantén el estudiante autenticado como fuente de identidad, separa notas de recomendaciones y no inventes métricas faltantes. Si encuentras una necesidad no cubierta, identifica la brecha y propone un cambio separado para revisión, sin modificar silenciosamente el esquema ni sus permisos. Indica qué verificaste y qué sigue pendiente.

Lista de trabajo obligatoria para agentes de integración
1. Verificar rama y archivos: 004 está en main; 005 debe estar incluida en la rama que se integra. No reconstruir un esquema diferente.
2. Separar cuatro estados: definido en SQL, aplicado en la base, probado por SQL e integrado por HTTP. Reportar evidencia para cada uno.
3. Instalar en orden 001 → 002 → 003 → seguridad → 004 → 005; en bases existentes aplicar solo lo pendiente. No ejecutar seeds ni migraciones automáticamente al arrancar la API.
4. Usar las diez funciones operativas según el caso y el rol limitado; no llamar a la auxiliar administrativa. No deshabilitar triggers, usar postgres, hacer sync/alter automático del ORM ni otorgar permisos generales para sortear un error.
5. Mantener actor autenticado, filtros por recurso y SQL parametrizado. No exponer hashes, claves correctas ni tokens; no añadir credenciales locales al repositorio.
6. Conservar NULL como ausencia de calificación. Contadores COUNT y NUMERIC pueden llegar como strings en pg; normalizar deliberadamente para el DTO/Python.
7. No crear progreso, interacciones, recomendaciones ni endpoints suponiendo que ya existen. Si se requieren nuevos endpoints, implementarlos en backend con pruebas y documentación, distinguiéndolos del contrato SQL existente.
8. Para el motor, acordar unidad inscripción/tema, selección de intentos y tratamiento de vacías/incorrectas; no mezclar intentos y promedios como observaciones equivalentes ni inventar métricas.
9. No modificar políticas de roles, reglas de finalización o calificación para acomodar código previo. Proponer cambios incrementales explícitos cuando la capacidad falte.
10. Probar con cuenta demo o fixtures aislados; no codificar IDs vistos en capturas. Mantener transacciones breves y no repetir una inscripción como si fuera idempotente.
11. Actualizar rutas y contratos HTTP reales, pruebas y ambos documentos en el PR. No afirmar que fechas/concurrencia de 004 están verificadas hasta ejecutar esos casos.

## Estado de la entrega y límites del contrato

El SQL y sus pruebas de cursos están listos para revisión. El responsable confirmó el seed administrativo y autenticación HTTP de ambas cuentas. Aún no se verificó el recorrido HTTP de cursos ni sus pantallas. Las decisiones del motor siguen pendientes; no se presentan como resueltas por 005.

El diccionario define tipos PostgreSQL y nulabilidad; no establece automáticamente DTOs. Backend y frontend deben acordar nombres JSON, tipos serializados y mensajes de error en OpenAPI. No devolver todas las columnas de las tablas por comodidad.
