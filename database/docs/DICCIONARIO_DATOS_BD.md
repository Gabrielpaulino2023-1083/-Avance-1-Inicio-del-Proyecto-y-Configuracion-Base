# Diccionario de datos — BD-005-v1

Referencia: migraciones 001–005 y seguridad. Fecha: 10 de noviembre de 2026.
Los tipos, nulabilidad, defaults, restricciones e índices siguientes se extrajeron del catálogo
PostgreSQL después de instalar los scripts en PGlite; no se dedujeron de ejemplos JSON.

## Cómo usarlo

- Backend: respetar tipos, restricciones y funciones del [contrato](CONTRATO_INTEGRACION_BD.md).
- Frontend: consumir DTOs de la API; no conectarse a PostgreSQL ni copiar todas las columnas.
- Los nombres SQL son exactos. La API puede usar camelCase si el mapeo queda documentado.
- `NULL permitido` expresa la definición de la columna; un CHECK o el estado puede exigir un valor.
- Un default se aplica al omitir una columna, no al enviar NULL explícitamente.
- Identity ALWAYS identifica IDs generados por la base: no enviarlos al crear.
- Los defaults de actualizado_en no actualizan el campo automáticamente en cada UPDATE.
- Las restricciones no enumeran toda la lógica de funciones/triggers: consultar el contrato.

## Reglas de intercambio propuestas para backend y frontend

Estas reglas son recomendaciones para acordar y reflejar en OpenAPI; no cambian los DTOs actuales.

| PostgreSQL | JSON/TypeScript propuesto | Precaución |
|---|---|---|
| integer | number entero | Validar rango y positividad cuando corresponda; no aceptar IDs fraccionarios |
| bigint, incluyendo COUNT | number seguro o string decimal acordado | pg puede devolver strings; no convertir fuera del rango seguro de JavaScript |
| numeric(10,2), numeric de la vista | number o string decimal, definido por campo | pg puede devolver string; preservar precisión, NULL y redondeo acordados |
| text / character varying(n) | string | Respetar longitud n cuando existe; TEXT no define máximo de producto |
| boolean | boolean | No enviar las cadenas "true"/"false" como sustituto |
| timestamp with time zone | string ISO 8601 con zona | Serializar explícitamente; mostrar en zona local sin perder el instante |
| integer[] como argumento | number[] | Selecciones completas, sin duplicados ni NULL; [] limpia la respuesta |
| columna nullable | tipo anterior o null | Ausente, null, cero y cadena vacía tienen significados distintos |
| texto con CHECK de estados | unión de cadenas o enum del DTO | Respetar mayúsculas y valores SQL exactos |

### Curso: ejemplo de correspondencia (propuesta de DTO)

| SQL | JSON propuesto | Tipo | ¿Lo envía el cliente al crear? |
|---|---|---|---|
| id | id | number | No |
| codigo | codigo | string | Sí |
| nombre | nombre | string | Sí |
| descripcion | descripcion | string | Sí |
| estado | estado | BORRADOR / ACTIVO / ARCHIVADO | No: nace BORRADOR |
| creado_por | creadoPor | number | No: actor autenticado |
| creado_en | creadoEn | string ISO 8601 | No |
| actualizado_en | actualizadoEn | string ISO 8601 | No |

El cambio de estado tiene una operación aparte. El contrato SQL exige código, nombre y
descripción completos al editar; si la API expone PATCH, el backend debe resolver esa diferencia.
El ID del actor nunca procede del body. No se fijan aquí rutas HTTP como implementadas.

### Campos internos y acceso

- usuarios.password_hash: solo autenticación interna, nunca respuestas de API.
- opciones_respuestas.es_correcta: el rol backend no tiene lectura directa de esa columna.
- preguntas.explicacion: el backend puede leerla, pero debe evitar exponer la solución antes del momento autorizado.
- Puntajes: el navegador no los asigna; las funciones de calificación los calculan.
- Intentos, inscripciones y resultados: filtrar por identidad y autorización; no hay RLS.

## Esquema exacto

### `actividades`

| Columna | Tipo PostgreSQL | NULL permitido | Predeterminado / generación |
|---|---|---|---|
| `id` | `integer` | No | GENERATED ALWAYS AS IDENTITY |
| `seccion_id` | `integer` | No | — |
| `tema_id` | `integer` | No | — |
| `titulo` | `text` | No | — |
| `instrucciones` | `text` | No | — |
| `finalidad` | `text` | No | 'PRACTICA'::text |
| `metodo_calificacion` | `text` | No | 'PROMEDIO'::text |
| `max_intentos` | `integer` | Sí | — |
| `duracion_minutos` | `integer` | Sí | — |
| `disponible_desde` | `timestamp with time zone` | No | — |
| `disponible_hasta` | `timestamp with time zone` | Sí | — |
| `estado` | `character varying(50)` | No | 'BORRADOR'::character varying |
| `creado_por` | `integer` | No | — |
| `creado_en` | `timestamp with time zone` | No | CURRENT_TIMESTAMP |
| `actualizado_en` | `timestamp with time zone` | No | CURRENT_TIMESTAMP |

Restricciones del esquema:

- `actividades_actualizado_en_not_null`: `NOT NULL actualizado_en`.
- `actividades_creado_en_not_null`: `NOT NULL creado_en`.
- `actividades_creado_por_fkey`: `FOREIGN KEY (creado_por) REFERENCES usuarios(id) ON DELETE RESTRICT`.
- `actividades_creado_por_not_null`: `NOT NULL creado_por`.
- `actividades_disponible_desde_not_null`: `NOT NULL disponible_desde`.
- `actividades_duracion_minutos_check`: `CHECK ((duracion_minutos > 0))`.
- `actividades_estado_check`: `CHECK (((estado)::text = ANY ((ARRAY['BORRADOR'::character varying, 'PUBLICADO'::character varying, 'ARCHIVADO'::character varying])::text[])))`.
- `actividades_estado_not_null`: `NOT NULL estado`.
- `actividades_finalidad_check`: `CHECK ((finalidad = ANY (ARRAY['EVALUACION'::text, 'PRACTICA'::text])))`.
- `actividades_finalidad_not_null`: `NOT NULL finalidad`.
- `actividades_id_not_null`: `NOT NULL id`.
- `actividades_instrucciones_check`: `CHECK ((btrim(instrucciones) <> ''::text))`.
- `actividades_instrucciones_not_null`: `NOT NULL instrucciones`.
- `actividades_max_intentos_check`: `CHECK ((max_intentos > 0))`.
- `actividades_metodo_calificacion_check`: `CHECK ((metodo_calificacion = 'PROMEDIO'::text))`.
- `actividades_metodo_calificacion_not_null`: `NOT NULL metodo_calificacion`.
- `actividades_pkey`: `PRIMARY KEY (id)`.
- `actividades_seccion_id_fkey`: `FOREIGN KEY (seccion_id) REFERENCES secciones(id) ON DELETE RESTRICT`.
- `actividades_seccion_id_not_null`: `NOT NULL seccion_id`.
- `actividades_tema_id_fkey`: `FOREIGN KEY (tema_id) REFERENCES temas(id) ON DELETE RESTRICT`.
- `actividades_tema_id_not_null`: `NOT NULL tema_id`.
- `actividades_titulo_check`: `CHECK ((btrim(titulo) <> ''::text))`.
- `actividades_titulo_not_null`: `NOT NULL titulo`.
- `ck_actividades_disponibilidad`: `CHECK (((disponible_hasta IS NULL) OR (disponible_hasta > disponible_desde)))`.
- `ck_actividades_fechas`: `CHECK ((actualizado_en >= creado_en))`.

### `curso_editores`

| Columna | Tipo PostgreSQL | NULL permitido | Predeterminado / generación |
|---|---|---|---|
| `id` | `integer` | No | GENERATED ALWAYS AS IDENTITY |
| `curso_id` | `integer` | No | — |
| `usuario_id` | `integer` | No | — |
| `activo` | `boolean` | No | true |
| `asignado_por` | `integer` | No | — |
| `asignado_en` | `timestamp with time zone` | No | CURRENT_TIMESTAMP |

Restricciones del esquema:

- `curso_editores_activo_not_null`: `NOT NULL activo`.
- `curso_editores_asignado_en_not_null`: `NOT NULL asignado_en`.
- `curso_editores_asignado_por_fkey`: `FOREIGN KEY (asignado_por) REFERENCES usuarios(id) ON DELETE RESTRICT`.
- `curso_editores_asignado_por_not_null`: `NOT NULL asignado_por`.
- `curso_editores_curso_id_fkey`: `FOREIGN KEY (curso_id) REFERENCES cursos(id) ON DELETE RESTRICT`.
- `curso_editores_curso_id_not_null`: `NOT NULL curso_id`.
- `curso_editores_curso_id_usuario_id_key`: `UNIQUE (curso_id, usuario_id)`.
- `curso_editores_id_not_null`: `NOT NULL id`.
- `curso_editores_pkey`: `PRIMARY KEY (id)`.
- `curso_editores_usuario_id_fkey`: `FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE RESTRICT`.
- `curso_editores_usuario_id_not_null`: `NOT NULL usuario_id`.

### `cursos`

| Columna | Tipo PostgreSQL | NULL permitido | Predeterminado / generación |
|---|---|---|---|
| `id` | `integer` | No | GENERATED ALWAYS AS IDENTITY |
| `codigo` | `text` | No | — |
| `nombre` | `text` | No | — |
| `descripcion` | `text` | No | — |
| `estado` | `character varying(50)` | No | 'BORRADOR'::character varying |
| `creado_por` | `integer` | No | — |
| `creado_en` | `timestamp with time zone` | No | CURRENT_TIMESTAMP |
| `actualizado_en` | `timestamp with time zone` | No | CURRENT_TIMESTAMP |

Restricciones del esquema:

- `cursos_actualizado_en_not_null`: `NOT NULL actualizado_en`.
- `cursos_check`: `CHECK ((actualizado_en >= creado_en))`.
- `cursos_codigo_check`: `CHECK ((btrim(codigo) <> ''::text))`.
- `cursos_codigo_key`: `UNIQUE (codigo)`.
- `cursos_codigo_not_null`: `NOT NULL codigo`.
- `cursos_creado_en_not_null`: `NOT NULL creado_en`.
- `cursos_creado_por_fkey`: `FOREIGN KEY (creado_por) REFERENCES usuarios(id) ON DELETE RESTRICT`.
- `cursos_creado_por_not_null`: `NOT NULL creado_por`.
- `cursos_descripcion_check`: `CHECK ((btrim(descripcion) <> ''::text))`.
- `cursos_descripcion_not_null`: `NOT NULL descripcion`.
- `cursos_estado_check`: `CHECK (((estado)::text = ANY ((ARRAY['BORRADOR'::character varying, 'ACTIVO'::character varying, 'ARCHIVADO'::character varying])::text[])))`.
- `cursos_estado_not_null`: `NOT NULL estado`.
- `cursos_id_not_null`: `NOT NULL id`.
- `cursos_nombre_check`: `CHECK ((btrim(nombre) <> ''::text))`.
- `cursos_nombre_not_null`: `NOT NULL nombre`.
- `cursos_pkey`: `PRIMARY KEY (id)`.

### `ediciones_curso`

| Columna | Tipo PostgreSQL | NULL permitido | Predeterminado / generación |
|---|---|---|---|
| `id` | `integer` | No | GENERATED ALWAYS AS IDENTITY |
| `curso_id` | `integer` | No | — |
| `codigo` | `text` | No | — |
| `nombre` | `text` | No | — |
| `fecha_inicio` | `timestamp with time zone` | No | — |
| `fecha_fin` | `timestamp with time zone` | No | — |
| `inscripcion_desde` | `timestamp with time zone` | Sí | — |
| `inscripcion_hasta` | `timestamp with time zone` | Sí | — |
| `estado` | `character varying(50)` | No | 'PLANIFICADA'::character varying |
| `creado_por` | `integer` | No | — |
| `creado_en` | `timestamp with time zone` | No | CURRENT_TIMESTAMP |

Restricciones del esquema:

- `ck_ediciones_fechas_obligatorias`: `CHECK ((((estado)::text = ANY ((ARRAY['PLANIFICADA'::character varying, 'CANCELADA'::character varying])::text[])) OR ((inscripcion_desde IS NOT NULL) AND (inscripcion_hasta IS NOT NULL))))`.
- `ck_ediciones_ventana_inscripcion`: `CHECK ((((inscripcion_desde IS NULL) AND (inscripcion_hasta IS NULL)) OR ((inscripcion_desde IS NOT NULL) AND (inscripcion_hasta IS NOT NULL) AND (inscripcion_hasta >= inscripcion_desde) AND (inscripcion_hasta <= fecha_fin))))`.
- `ediciones_curso_check`: `CHECK ((fecha_fin >= fecha_inicio))`.
- `ediciones_curso_codigo_check`: `CHECK ((btrim(codigo) <> ''::text))`.
- `ediciones_curso_codigo_not_null`: `NOT NULL codigo`.
- `ediciones_curso_creado_en_not_null`: `NOT NULL creado_en`.
- `ediciones_curso_creado_por_fkey`: `FOREIGN KEY (creado_por) REFERENCES usuarios(id) ON DELETE RESTRICT`.
- `ediciones_curso_creado_por_not_null`: `NOT NULL creado_por`.
- `ediciones_curso_curso_id_codigo_key`: `UNIQUE (curso_id, codigo)`.
- `ediciones_curso_curso_id_fkey`: `FOREIGN KEY (curso_id) REFERENCES cursos(id) ON DELETE RESTRICT`.
- `ediciones_curso_curso_id_not_null`: `NOT NULL curso_id`.
- `ediciones_curso_estado_check`: `CHECK (((estado)::text = ANY ((ARRAY['PLANIFICADA'::character varying, 'ABIERTA'::character varying, 'EN_CURSO'::character varying, 'FINALIZADA'::character varying, 'CANCELADA'::character varying])::text[])))`.
- `ediciones_curso_estado_not_null`: `NOT NULL estado`.
- `ediciones_curso_fecha_fin_not_null`: `NOT NULL fecha_fin`.
- `ediciones_curso_fecha_inicio_not_null`: `NOT NULL fecha_inicio`.
- `ediciones_curso_id_not_null`: `NOT NULL id`.
- `ediciones_curso_nombre_check`: `CHECK ((btrim(nombre) <> ''::text))`.
- `ediciones_curso_nombre_not_null`: `NOT NULL nombre`.
- `ediciones_curso_pkey`: `PRIMARY KEY (id)`.

### `inscripciones`

| Columna | Tipo PostgreSQL | NULL permitido | Predeterminado / generación |
|---|---|---|---|
| `id` | `integer` | No | GENERATED ALWAYS AS IDENTITY |
| `estudiante_id` | `integer` | No | — |
| `edicion_id` | `integer` | No | — |
| `seccion_id` | `integer` | No | — |
| `estado` | `character varying(50)` | No | 'ACTIVA'::character varying |
| `origen` | `character varying(50)` | No | — |
| `registrado_por` | `integer` | No | — |
| `inscrito_en` | `timestamp with time zone` | No | CURRENT_TIMESTAMP |
| `cerrado_en` | `timestamp with time zone` | Sí | — |

Restricciones del esquema:

- `ck_inscripciones_cierre`: `CHECK (((((estado)::text = 'ACTIVA'::text) AND (cerrado_en IS NULL)) OR (((estado)::text <> 'ACTIVA'::text) AND (cerrado_en IS NOT NULL) AND (cerrado_en >= inscrito_en))))`.
- `ck_inscripciones_origen`: `CHECK ((((origen)::text <> 'AUTONOMA'::text) OR (registrado_por = estudiante_id)))`.
- `fk_inscripciones_seccion_edicion`: `FOREIGN KEY (seccion_id, edicion_id) REFERENCES secciones(id, edicion_id) ON DELETE RESTRICT`.
- `inscripciones_edicion_id_fkey`: `FOREIGN KEY (edicion_id) REFERENCES ediciones_curso(id) ON DELETE RESTRICT`.
- `inscripciones_edicion_id_not_null`: `NOT NULL edicion_id`.
- `inscripciones_estado_check`: `CHECK (((estado)::text = ANY ((ARRAY['ACTIVA'::character varying, 'RETIRADA'::character varying, 'COMPLETADA'::character varying, 'CANCELADA'::character varying])::text[])))`.
- `inscripciones_estado_not_null`: `NOT NULL estado`.
- `inscripciones_estudiante_id_edicion_id_key`: `UNIQUE (estudiante_id, edicion_id)`.
- `inscripciones_estudiante_id_fkey`: `FOREIGN KEY (estudiante_id) REFERENCES usuarios(id) ON DELETE RESTRICT`.
- `inscripciones_estudiante_id_not_null`: `NOT NULL estudiante_id`.
- `inscripciones_id_not_null`: `NOT NULL id`.
- `inscripciones_inscrito_en_not_null`: `NOT NULL inscrito_en`.
- `inscripciones_origen_check`: `CHECK (((origen)::text = ANY ((ARRAY['AUTONOMA'::character varying, 'ADMINISTRATIVA'::character varying])::text[])))`.
- `inscripciones_origen_not_null`: `NOT NULL origen`.
- `inscripciones_pkey`: `PRIMARY KEY (id)`.
- `inscripciones_registrado_por_fkey`: `FOREIGN KEY (registrado_por) REFERENCES usuarios(id) ON DELETE RESTRICT`.
- `inscripciones_registrado_por_not_null`: `NOT NULL registrado_por`.
- `inscripciones_seccion_id_not_null`: `NOT NULL seccion_id`.

### `intentos`

| Columna | Tipo PostgreSQL | NULL permitido | Predeterminado / generación |
|---|---|---|---|
| `id` | `integer` | No | GENERATED ALWAYS AS IDENTITY |
| `actividad_id` | `integer` | No | — |
| `inscripcion_id` | `integer` | No | — |
| `numero_intento` | `integer` | No | — |
| `estado` | `text` | No | 'EN_CURSO'::text |
| `iniciado_en` | `timestamp with time zone` | No | CURRENT_TIMESTAMP |
| `vence_en` | `timestamp with time zone` | Sí | — |
| `entregado_en` | `timestamp with time zone` | Sí | — |
| `motivo_entrega` | `text` | Sí | — |
| `calificado_en` | `timestamp with time zone` | Sí | — |
| `puntaje_obtenido` | `numeric(10,2)` | Sí | — |
| `puntaje_maximo` | `numeric(10,2)` | No | — |

Restricciones del esquema:

- `ck_intentos_calificacion_fecha`: `CHECK (((calificado_en IS NULL) OR ((entregado_en IS NOT NULL) AND (calificado_en >= entregado_en))))`.
- `ck_intentos_entrega_fecha`: `CHECK (((entregado_en IS NULL) OR (entregado_en >= iniciado_en)))`.
- `ck_intentos_entrega_vencimiento`: `CHECK (((motivo_entrega IS DISTINCT FROM 'VENCIMIENTO'::text) OR ((vence_en IS NOT NULL) AND (entregado_en IS NOT NULL) AND (entregado_en >= vence_en))))`.
- `ck_intentos_estado_datos`: `CHECK ((((estado = 'EN_CURSO'::text) AND (entregado_en IS NULL) AND (motivo_entrega IS NULL) AND (calificado_en IS NULL) AND (puntaje_obtenido IS NULL)) OR ((estado = 'ENTREGADO'::text) AND (entregado_en IS NOT NULL) AND (motivo_entrega IS NOT NULL) AND (calificado_en IS NULL) AND (puntaje_obtenido IS NULL)) OR ((estado = 'CALIFICADO'::text) AND (entregado_en IS NOT NULL) AND (motivo_entrega IS NOT NULL) AND (calificado_en IS NOT NULL) AND (puntaje_obtenido IS NOT NULL))))`.
- `ck_intentos_puntaje`: `CHECK ((puntaje_obtenido <= puntaje_maximo))`.
- `ck_intentos_vencimiento`: `CHECK (((vence_en IS NULL) OR (vence_en >= iniciado_en)))`.
- `intentos_actividad_id_fkey`: `FOREIGN KEY (actividad_id) REFERENCES actividades(id) ON DELETE RESTRICT`.
- `intentos_actividad_id_not_null`: `NOT NULL actividad_id`.
- `intentos_estado_check`: `CHECK ((estado = ANY (ARRAY['EN_CURSO'::text, 'ENTREGADO'::text, 'CALIFICADO'::text])))`.
- `intentos_estado_not_null`: `NOT NULL estado`.
- `intentos_id_not_null`: `NOT NULL id`.
- `intentos_iniciado_en_not_null`: `NOT NULL iniciado_en`.
- `intentos_inscripcion_id_fkey`: `FOREIGN KEY (inscripcion_id) REFERENCES inscripciones(id) ON DELETE RESTRICT`.
- `intentos_inscripcion_id_not_null`: `NOT NULL inscripcion_id`.
- `intentos_motivo_entrega_check`: `CHECK ((motivo_entrega = ANY (ARRAY['MANUAL'::text, 'VENCIMIENTO'::text])))`.
- `intentos_numero_intento_check`: `CHECK ((numero_intento > 0))`.
- `intentos_numero_intento_not_null`: `NOT NULL numero_intento`.
- `intentos_pkey`: `PRIMARY KEY (id)`.
- `intentos_puntaje_maximo_check`: `CHECK (((puntaje_maximo > (0)::numeric) AND (puntaje_maximo <> 'NaN'::numeric)))`.
- `intentos_puntaje_maximo_not_null`: `NOT NULL puntaje_maximo`.
- `intentos_puntaje_obtenido_check`: `CHECK (((puntaje_obtenido >= (0)::numeric) AND (puntaje_obtenido <> 'NaN'::numeric)))`.
- `uq_intentos_actividad_inscripcion_numero`: `UNIQUE (actividad_id, inscripcion_id, numero_intento)`.
- `uq_intentos_id_actividad`: `UNIQUE (id, actividad_id)`.

Índice adicional: `CREATE UNIQUE INDEX uq_intentos_uno_en_curso ON public.intentos USING btree (actividad_id, inscripcion_id) WHERE (estado = 'EN_CURSO'::text)`.

### `modulos`

| Columna | Tipo PostgreSQL | NULL permitido | Predeterminado / generación |
|---|---|---|---|
| `id` | `integer` | No | GENERATED ALWAYS AS IDENTITY |
| `curso_id` | `integer` | No | — |
| `nombre` | `text` | No | — |
| `descripcion` | `text` | No | — |
| `orden` | `integer` | No | — |
| `estado` | `character varying(50)` | No | 'BORRADOR'::character varying |
| `creado_por` | `integer` | No | — |
| `creado_en` | `timestamp with time zone` | No | CURRENT_TIMESTAMP |
| `actualizado_en` | `timestamp with time zone` | No | CURRENT_TIMESTAMP |

Restricciones del esquema:

- `ck_modulos_fechas`: `CHECK ((actualizado_en >= creado_en))`.
- `modulos_actualizado_en_not_null`: `NOT NULL actualizado_en`.
- `modulos_creado_en_not_null`: `NOT NULL creado_en`.
- `modulos_creado_por_fkey`: `FOREIGN KEY (creado_por) REFERENCES usuarios(id) ON DELETE RESTRICT`.
- `modulos_creado_por_not_null`: `NOT NULL creado_por`.
- `modulos_curso_id_fkey`: `FOREIGN KEY (curso_id) REFERENCES cursos(id) ON DELETE RESTRICT`.
- `modulos_curso_id_not_null`: `NOT NULL curso_id`.
- `modulos_descripcion_check`: `CHECK ((btrim(descripcion) <> ''::text))`.
- `modulos_descripcion_not_null`: `NOT NULL descripcion`.
- `modulos_estado_check`: `CHECK (((estado)::text = ANY ((ARRAY['BORRADOR'::character varying, 'PUBLICADO'::character varying, 'ARCHIVADO'::character varying])::text[])))`.
- `modulos_estado_not_null`: `NOT NULL estado`.
- `modulos_id_not_null`: `NOT NULL id`.
- `modulos_nombre_check`: `CHECK ((btrim(nombre) <> ''::text))`.
- `modulos_nombre_not_null`: `NOT NULL nombre`.
- `modulos_orden_check`: `CHECK ((orden > 0))`.
- `modulos_orden_not_null`: `NOT NULL orden`.
- `modulos_pkey`: `PRIMARY KEY (id)`.
- `uq_modulos_curso_orden`: `UNIQUE (curso_id, orden)`.

### `opciones_respuestas`

| Columna | Tipo PostgreSQL | NULL permitido | Predeterminado / generación |
|---|---|---|---|
| `id` | `integer` | No | GENERATED ALWAYS AS IDENTITY |
| `pregunta_id` | `integer` | No | — |
| `texto` | `text` | No | — |
| `orden` | `integer` | No | — |
| `es_correcta` | `boolean` | No | false |

Restricciones del esquema:

- `opciones_respuestas_es_correcta_not_null`: `NOT NULL es_correcta`.
- `opciones_respuestas_id_not_null`: `NOT NULL id`.
- `opciones_respuestas_orden_check`: `CHECK ((orden > 0))`.
- `opciones_respuestas_orden_not_null`: `NOT NULL orden`.
- `opciones_respuestas_pkey`: `PRIMARY KEY (id)`.
- `opciones_respuestas_pregunta_id_fkey`: `FOREIGN KEY (pregunta_id) REFERENCES preguntas(id) ON DELETE RESTRICT`.
- `opciones_respuestas_pregunta_id_not_null`: `NOT NULL pregunta_id`.
- `opciones_respuestas_texto_check`: `CHECK ((btrim(texto) <> ''::text))`.
- `opciones_respuestas_texto_not_null`: `NOT NULL texto`.
- `uq_opciones_id_pregunta`: `UNIQUE (id, pregunta_id)`.
- `uq_opciones_pregunta_orden`: `UNIQUE (pregunta_id, orden)`.

### `preguntas`

| Columna | Tipo PostgreSQL | NULL permitido | Predeterminado / generación |
|---|---|---|---|
| `id` | `integer` | No | GENERATED ALWAYS AS IDENTITY |
| `actividad_id` | `integer` | No | — |
| `enunciado` | `text` | No | — |
| `tipo` | `text` | No | 'SELECCION_UNICA'::text |
| `orden` | `integer` | No | — |
| `puntaje_maximo` | `numeric(10,2)` | No | — |
| `explicacion` | `text` | Sí | — |

Restricciones del esquema:

- `preguntas_actividad_id_fkey`: `FOREIGN KEY (actividad_id) REFERENCES actividades(id) ON DELETE RESTRICT`.
- `preguntas_actividad_id_not_null`: `NOT NULL actividad_id`.
- `preguntas_enunciado_check`: `CHECK ((btrim(enunciado) <> ''::text))`.
- `preguntas_enunciado_not_null`: `NOT NULL enunciado`.
- `preguntas_explicacion_check`: `CHECK ((btrim(explicacion) <> ''::text))`.
- `preguntas_id_not_null`: `NOT NULL id`.
- `preguntas_orden_check`: `CHECK ((orden > 0))`.
- `preguntas_orden_not_null`: `NOT NULL orden`.
- `preguntas_pkey`: `PRIMARY KEY (id)`.
- `preguntas_puntaje_maximo_check`: `CHECK (((puntaje_maximo > (0)::numeric) AND (puntaje_maximo <> 'NaN'::numeric)))`.
- `preguntas_puntaje_maximo_not_null`: `NOT NULL puntaje_maximo`.
- `preguntas_tipo_check`: `CHECK ((tipo = ANY (ARRAY['SELECCION_UNICA'::text, 'SELECCION_MULTIPLE'::text])))`.
- `preguntas_tipo_not_null`: `NOT NULL tipo`.
- `uq_preguntas_actividad_orden`: `UNIQUE (actividad_id, orden)`.
- `uq_preguntas_id_actividad`: `UNIQUE (id, actividad_id)`.

### `respuesta_opciones`

| Columna | Tipo PostgreSQL | NULL permitido | Predeterminado / generación |
|---|---|---|---|
| `respuesta_id` | `integer` | No | — |
| `pregunta_id` | `integer` | No | — |
| `opcion_id` | `integer` | No | — |

Restricciones del esquema:

- `fk_respuesta_opciones_opcion`: `FOREIGN KEY (opcion_id, pregunta_id) REFERENCES opciones_respuestas(id, pregunta_id) ON DELETE RESTRICT`.
- `fk_respuesta_opciones_respuesta`: `FOREIGN KEY (respuesta_id, pregunta_id) REFERENCES respuestas(id, pregunta_id) ON DELETE RESTRICT`.
- `pk_respuesta_opciones`: `PRIMARY KEY (respuesta_id, opcion_id)`.
- `respuesta_opciones_opcion_id_not_null`: `NOT NULL opcion_id`.
- `respuesta_opciones_pregunta_id_not_null`: `NOT NULL pregunta_id`.
- `respuesta_opciones_respuesta_id_not_null`: `NOT NULL respuesta_id`.

### `respuestas`

| Columna | Tipo PostgreSQL | NULL permitido | Predeterminado / generación |
|---|---|---|---|
| `id` | `integer` | No | GENERATED ALWAYS AS IDENTITY |
| `intento_id` | `integer` | No | — |
| `pregunta_id` | `integer` | No | — |
| `actividad_id` | `integer` | No | — |
| `creado_en` | `timestamp with time zone` | No | CURRENT_TIMESTAMP |
| `actualizado_en` | `timestamp with time zone` | No | CURRENT_TIMESTAMP |
| `calificado_en` | `timestamp with time zone` | Sí | — |
| `puntaje_obtenido` | `numeric(10,2)` | Sí | — |

Restricciones del esquema:

- `ck_respuestas_calificacion`: `CHECK ((((calificado_en IS NULL) AND (puntaje_obtenido IS NULL)) OR ((calificado_en IS NOT NULL) AND (puntaje_obtenido IS NOT NULL) AND (calificado_en >= creado_en))))`.
- `ck_respuestas_fechas`: `CHECK ((actualizado_en >= creado_en))`.
- `fk_respuestas_intento_actividad`: `FOREIGN KEY (intento_id, actividad_id) REFERENCES intentos(id, actividad_id) ON DELETE RESTRICT`.
- `fk_respuestas_pregunta_actividad`: `FOREIGN KEY (pregunta_id, actividad_id) REFERENCES preguntas(id, actividad_id) ON DELETE RESTRICT`.
- `respuestas_actividad_id_not_null`: `NOT NULL actividad_id`.
- `respuestas_actualizado_en_not_null`: `NOT NULL actualizado_en`.
- `respuestas_creado_en_not_null`: `NOT NULL creado_en`.
- `respuestas_id_not_null`: `NOT NULL id`.
- `respuestas_intento_id_not_null`: `NOT NULL intento_id`.
- `respuestas_pkey`: `PRIMARY KEY (id)`.
- `respuestas_pregunta_id_not_null`: `NOT NULL pregunta_id`.
- `respuestas_puntaje_obtenido_check`: `CHECK (((puntaje_obtenido >= (0)::numeric) AND (puntaje_obtenido <> 'NaN'::numeric)))`.
- `uq_respuestas_id_pregunta`: `UNIQUE (id, pregunta_id)`.
- `uq_respuestas_intento_pregunta`: `UNIQUE (intento_id, pregunta_id)`.

### `resultados_actividades` — vista de solo consulta

La nulabilidad declarada de una vista no prueba qué expresiones siempre generan valores. Sin intentos no hay fila; sin calificados, el promedio es NULL. PRACTICA no tiene nota académica.

| Columna | Tipo PostgreSQL | NULL permitido | Predeterminado / generación |
|---|---|---|---|
| `actividad_id` | `integer` | No garantizado por catálogo de vista | — |
| `titulo` | `text` | No garantizado por catálogo de vista | — |
| `seccion_id` | `integer` | No garantizado por catálogo de vista | — |
| `tema_id` | `integer` | No garantizado por catálogo de vista | — |
| `finalidad` | `text` | No garantizado por catálogo de vista | — |
| `metodo_calificacion` | `text` | No garantizado por catálogo de vista | — |
| `inscripcion_id` | `integer` | No garantizado por catálogo de vista | — |
| `estudiante_id` | `integer` | No garantizado por catálogo de vista | — |
| `intentos_iniciados` | `bigint` | No garantizado por catálogo de vista | — |
| `intentos_en_curso` | `bigint` | No garantizado por catálogo de vista | — |
| `intentos_pendientes_calificacion` | `bigint` | No garantizado por catálogo de vista | — |
| `intentos_calificados` | `bigint` | No garantizado por catálogo de vista | — |
| `promedio_porcentaje` | `numeric` | No garantizado por catálogo de vista | — |
| `nota_academica_porcentaje` | `numeric` | No garantizado por catálogo de vista | — |

### `roles`

| Columna | Tipo PostgreSQL | NULL permitido | Predeterminado / generación |
|---|---|---|---|
| `id` | `integer` | No | GENERATED ALWAYS AS IDENTITY |
| `codigo` | `character varying(50)` | No | — |
| `nombre` | `character varying(50)` | No | — |

Restricciones del esquema:

- `roles_codigo_check`: `CHECK (((codigo)::text = ANY ((ARRAY['ESTUDIANTE'::character varying, 'DOCENTE'::character varying, 'ADMINISTRADOR'::character varying])::text[])))`.
- `roles_codigo_key`: `UNIQUE (codigo)`.
- `roles_codigo_not_null`: `NOT NULL codigo`.
- `roles_id_not_null`: `NOT NULL id`.
- `roles_nombre_check`: `CHECK ((btrim((nombre)::text) <> ''::text))`.
- `roles_nombre_not_null`: `NOT NULL nombre`.
- `roles_pkey`: `PRIMARY KEY (id)`.

### `seccion_docentes`

| Columna | Tipo PostgreSQL | NULL permitido | Predeterminado / generación |
|---|---|---|---|
| `id` | `integer` | No | GENERATED ALWAYS AS IDENTITY |
| `seccion_id` | `integer` | No | — |
| `usuario_id` | `integer` | No | — |
| `activo` | `boolean` | No | true |
| `asignado_por` | `integer` | No | — |
| `asignado_en` | `timestamp with time zone` | No | CURRENT_TIMESTAMP |

Restricciones del esquema:

- `seccion_docentes_activo_not_null`: `NOT NULL activo`.
- `seccion_docentes_asignado_en_not_null`: `NOT NULL asignado_en`.
- `seccion_docentes_asignado_por_fkey`: `FOREIGN KEY (asignado_por) REFERENCES usuarios(id) ON DELETE RESTRICT`.
- `seccion_docentes_asignado_por_not_null`: `NOT NULL asignado_por`.
- `seccion_docentes_id_not_null`: `NOT NULL id`.
- `seccion_docentes_pkey`: `PRIMARY KEY (id)`.
- `seccion_docentes_seccion_id_fkey`: `FOREIGN KEY (seccion_id) REFERENCES secciones(id) ON DELETE RESTRICT`.
- `seccion_docentes_seccion_id_not_null`: `NOT NULL seccion_id`.
- `seccion_docentes_seccion_id_usuario_id_key`: `UNIQUE (seccion_id, usuario_id)`.
- `seccion_docentes_usuario_id_fkey`: `FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE RESTRICT`.
- `seccion_docentes_usuario_id_not_null`: `NOT NULL usuario_id`.

### `secciones`

| Columna | Tipo PostgreSQL | NULL permitido | Predeterminado / generación |
|---|---|---|---|
| `id` | `integer` | No | GENERATED ALWAYS AS IDENTITY |
| `edicion_id` | `integer` | No | — |
| `codigo` | `text` | No | — |
| `cupo_maximo` | `integer` | No | — |
| `estado` | `character varying(50)` | No | 'CERRADA'::character varying |
| `creado_por` | `integer` | No | — |
| `creado_en` | `timestamp with time zone` | No | CURRENT_TIMESTAMP |

Restricciones del esquema:

- `secciones_codigo_check`: `CHECK ((btrim(codigo) <> ''::text))`.
- `secciones_codigo_not_null`: `NOT NULL codigo`.
- `secciones_creado_en_not_null`: `NOT NULL creado_en`.
- `secciones_creado_por_fkey`: `FOREIGN KEY (creado_por) REFERENCES usuarios(id) ON DELETE RESTRICT`.
- `secciones_creado_por_not_null`: `NOT NULL creado_por`.
- `secciones_cupo_maximo_check`: `CHECK ((cupo_maximo > 0))`.
- `secciones_cupo_maximo_not_null`: `NOT NULL cupo_maximo`.
- `secciones_edicion_id_codigo_key`: `UNIQUE (edicion_id, codigo)`.
- `secciones_edicion_id_fkey`: `FOREIGN KEY (edicion_id) REFERENCES ediciones_curso(id) ON DELETE RESTRICT`.
- `secciones_edicion_id_not_null`: `NOT NULL edicion_id`.
- `secciones_estado_check`: `CHECK (((estado)::text = ANY ((ARRAY['ABIERTA'::character varying, 'CERRADA'::character varying, 'CANCELADA'::character varying])::text[])))`.
- `secciones_estado_not_null`: `NOT NULL estado`.
- `secciones_id_edicion_id_key`: `UNIQUE (id, edicion_id)`.
- `secciones_id_not_null`: `NOT NULL id`.
- `secciones_pkey`: `PRIMARY KEY (id)`.

### `temas`

| Columna | Tipo PostgreSQL | NULL permitido | Predeterminado / generación |
|---|---|---|---|
| `id` | `integer` | No | GENERATED ALWAYS AS IDENTITY |
| `modulo_id` | `integer` | No | — |
| `nombre` | `text` | No | — |
| `descripcion` | `text` | No | — |
| `orden` | `integer` | No | — |
| `estado` | `character varying(50)` | No | 'BORRADOR'::character varying |
| `creado_por` | `integer` | No | — |
| `creado_en` | `timestamp with time zone` | No | CURRENT_TIMESTAMP |
| `actualizado_en` | `timestamp with time zone` | No | CURRENT_TIMESTAMP |

Restricciones del esquema:

- `ck_temas_fechas`: `CHECK ((actualizado_en >= creado_en))`.
- `temas_actualizado_en_not_null`: `NOT NULL actualizado_en`.
- `temas_creado_en_not_null`: `NOT NULL creado_en`.
- `temas_creado_por_fkey`: `FOREIGN KEY (creado_por) REFERENCES usuarios(id) ON DELETE RESTRICT`.
- `temas_creado_por_not_null`: `NOT NULL creado_por`.
- `temas_descripcion_check`: `CHECK ((btrim(descripcion) <> ''::text))`.
- `temas_descripcion_not_null`: `NOT NULL descripcion`.
- `temas_estado_check`: `CHECK (((estado)::text = ANY ((ARRAY['BORRADOR'::character varying, 'PUBLICADO'::character varying, 'ARCHIVADO'::character varying])::text[])))`.
- `temas_estado_not_null`: `NOT NULL estado`.
- `temas_id_not_null`: `NOT NULL id`.
- `temas_modulo_id_fkey`: `FOREIGN KEY (modulo_id) REFERENCES modulos(id) ON DELETE RESTRICT`.
- `temas_modulo_id_not_null`: `NOT NULL modulo_id`.
- `temas_nombre_check`: `CHECK ((btrim(nombre) <> ''::text))`.
- `temas_nombre_not_null`: `NOT NULL nombre`.
- `temas_orden_check`: `CHECK ((orden > 0))`.
- `temas_orden_not_null`: `NOT NULL orden`.
- `temas_pkey`: `PRIMARY KEY (id)`.
- `uq_temas_modulo_orden`: `UNIQUE (modulo_id, orden)`.

### `usuario_roles`

| Columna | Tipo PostgreSQL | NULL permitido | Predeterminado / generación |
|---|---|---|---|
| `id` | `integer` | No | GENERATED ALWAYS AS IDENTITY |
| `usuario_id` | `integer` | No | — |
| `rol_id` | `integer` | No | — |
| `activo` | `boolean` | No | true |
| `asignado_por` | `integer` | No | — |
| `asignado_en` | `timestamp with time zone` | No | CURRENT_TIMESTAMP |
| `desactivado_en` | `timestamp with time zone` | Sí | — |

Restricciones del esquema:

- `ck_usuario_roles_desactivacion`: `CHECK ((((activo = true) AND (desactivado_en IS NULL)) OR ((activo = false) AND (desactivado_en IS NOT NULL) AND (desactivado_en >= asignado_en))))`.
- `usuario_roles_activo_not_null`: `NOT NULL activo`.
- `usuario_roles_asignado_en_not_null`: `NOT NULL asignado_en`.
- `usuario_roles_asignado_por_fkey`: `FOREIGN KEY (asignado_por) REFERENCES usuarios(id) ON DELETE RESTRICT`.
- `usuario_roles_asignado_por_not_null`: `NOT NULL asignado_por`.
- `usuario_roles_id_not_null`: `NOT NULL id`.
- `usuario_roles_pkey`: `PRIMARY KEY (id)`.
- `usuario_roles_rol_id_fkey`: `FOREIGN KEY (rol_id) REFERENCES roles(id) ON DELETE RESTRICT`.
- `usuario_roles_rol_id_not_null`: `NOT NULL rol_id`.
- `usuario_roles_usuario_id_fkey`: `FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE RESTRICT`.
- `usuario_roles_usuario_id_not_null`: `NOT NULL usuario_id`.
- `usuario_roles_usuario_id_rol_id_key`: `UNIQUE (usuario_id, rol_id)`.

### `usuarios`

| Columna | Tipo PostgreSQL | NULL permitido | Predeterminado / generación |
|---|---|---|---|
| `id` | `integer` | No | GENERATED ALWAYS AS IDENTITY |
| `nombre` | `character varying(50)` | No | — |
| `apellido` | `character varying(50)` | No | — |
| `email` | `text` | No | — |
| `password_hash` | `text` | No | — |
| `activo` | `boolean` | No | true |
| `creado_en` | `timestamp with time zone` | No | CURRENT_TIMESTAMP |
| `actualizado_en` | `timestamp with time zone` | No | CURRENT_TIMESTAMP |

Restricciones del esquema:

- `usuarios_activo_not_null`: `NOT NULL activo`.
- `usuarios_actualizado_en_not_null`: `NOT NULL actualizado_en`.
- `usuarios_apellido_check`: `CHECK ((btrim((apellido)::text) <> ''::text))`.
- `usuarios_apellido_not_null`: `NOT NULL apellido`.
- `usuarios_check`: `CHECK ((actualizado_en >= creado_en))`.
- `usuarios_creado_en_not_null`: `NOT NULL creado_en`.
- `usuarios_email_check`: `CHECK (((btrim(email) <> ''::text) AND (email = btrim(email))))`.
- `usuarios_email_not_null`: `NOT NULL email`.
- `usuarios_id_not_null`: `NOT NULL id`.
- `usuarios_nombre_check`: `CHECK ((btrim((nombre)::text) <> ''::text))`.
- `usuarios_nombre_not_null`: `NOT NULL nombre`.
- `usuarios_password_hash_check`: `CHECK ((btrim(password_hash) <> ''::text))`.
- `usuarios_password_hash_not_null`: `NOT NULL password_hash`.
- `usuarios_pkey`: `PRIMARY KEY (id)`.

Índice adicional: `CREATE UNIQUE INDEX uq_usuarios_email ON public.usuarios USING btree (lower(email))`.

## Semántica que debe conservarse

- max_intentos/duracion_minutos NULL: sin ese límite; cero no es válido.
- disponible_hasta NULL: sin cierre definido por la actividad.
- puntaje_obtenido NULL: pendiente de calificar; 0 es una calificación existente.
- respuesta_opciones sin filas: pregunta sin contestar; el registro respuestas sí existe.
- promedio_porcentaje usa intentos CALIFICADO. No sustituir ausencia por cero.
- nota_academica_porcentaje es de actividad, no nota final del curso ni progreso.
- numero_intento no es automáticamente el campo attempts del motor.
- entregado_en - iniciado_en es tiempo transcurrido, no tiempo activo de estudio.

No se agregaron columnas para progreso, navegación, recomendaciones o contenidos mediante 005.
Los DTOs definitivos deben acordarse con backend/frontend y validarse con ejemplos reales de API.
