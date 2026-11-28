# Gestión docente de actividades y cuestionarios — BD-010-v1

Fecha: 25 de noviembre de 2026. Base revisada: main `38066d2472fcb9521dcb362f681d76fbb9ccd305`.

**Estado: entrega local, implementada y probada en PostgreSQL 18.6 nativo. No publicada en GitHub.** Falta que Jeison la pruebe en su entorno y el equipo revise el contrato. Los endpoints y las pantallas de gestión de cuestionarios no forman parte del paquete.

## Alcance y dependencias

Requiere migraciones 001–009 y `security/001_roles_permisos.sql`. Agrega **20 funciones públicas, 7 funciones privadas (incluida una de trigger) y un trigger de borrado**. No agrega tablas/columnas ni redefine funciones anteriores. Tras instalar: 17 tablas, 73 funciones propias, 11 triggers y una vista, sin extensiones ni auxiliares temporales.

El docente puede preparar actividades fuera de los seeds, con preguntas y opciones; publicar, archivar, copiar y eliminar borradores. La operación se puede usar desde SQL antes de desarrollar la API. Los seeds siguen sirviendo para demostración.

- [Firmas, parámetros y tipos de retorno](FIRMAS_010.md).
- [Resultados de validación](../test/RESULTADO_VALIDACION_010.md).
- Instalación y primera prueba: [LEEME_010.md](../LEEME_010.md).

## Permisos por actor

| Actor | Alcance editorial |
|---|---|
| ADMINISTRADOR activo | Cualquier sección/tema del mismo curso que permita edición |
| DOCENTE activo | Debe tener curso_editores activo **y** seccion_docentes activo para la sección de la actividad |
| ESTUDIANTE | Ninguna operación editorial, ni lectura de claves por estas funciones |

La autoría no concede permisos permanentes: un docente revocado pierde acceso aunque haya creado el contenido. El administrador puede leer contenido histórico; el docente también si conserva las asignaciones. No es suficiente conocer el ID.

Actor siempre obtenido del JWT verificado por backend; no aceptarlo del body. La BD no verifica JWT ni distingue usuarios de aplicación mediante la conexión compartida. Backend mantiene la autenticación y controla qué función expone por endpoint.

La escritura editorial se rechaza si el curso, módulo o tema está ARCHIVADO, la edición FINALIZADA/CANCELADA o la sección CANCELADA. Las lecturas históricas autorizadas se permiten. Una sección CERRADA no equivale a CANCELADA; no se impide preparar contenido por cerrar inscripciones. Se puede preparar un borrador en curso BORRADOR/edición PLANIFICADA; el acceso del estudiante sigue sujeto a 007.

## Actividades

`crear_actividad` siempre crea BORRADOR con método PROMEDIO. Campos: sección, tema, título, instrucciones, finalidad, dificultad, máximo de intentos, duración y ventana de disponibilidad. `actualizar_actividad` recibe todos los campos editables, no es PATCH. No cambia autor, tema, sección o método.

| Campo | Tipo / regla |
|---|---|
| actor, sección, tema e IDs | INTEGER positivo |
| título, instrucciones | TEXT no vacío; se recortan extremos |
| finalidad | PRACTICA o EVALUACION |
| dificultad | BAJA, MEDIA, ALTA o NULL mientras se prepara el borrador |
| máximo de intentos, duración en minutos | INTEGER positivo o NULL (sin límite / sin temporizador, respectivamente) |
| desde | TIMESTAMPTZ finito obligatorio |
| hasta | TIMESTAMPTZ finito, mayor que desde; NULL = sin cierre |

Las funciones de escritura son atómicas y actualizan actualizado_en de la actividad, también al modificar hijos. Los resultados son filas SQL tipadas, no respuestas HTTP. La lectura editorial no devuelve datos de intentos de otros alumnos ni calcula notas.

## Ciclo de vida

- BORRADOR sin intentos: editable, reordenable y eliminable. Puede estar incompleto durante la preparación.
- PUBLICADO: no editable mediante 010. Sin intentos puede volver a BORRADOR para corregirse.
- Con cualquier intento: nunca vuelve a BORRADOR, no se edita ni borra su contenido. Para otra versión, usar duplicar_actividad.
- ARCHIVADO sin intentos: puede volver a BORRADOR. Con historial puede republicarse conservando contenido y superando nuevamente las validaciones.
- Para archivar mediante 010 no puede existir un intento EN_CURSO, incluso vencido. Debe entregarse con el flujo existente; el barrido automático sigue pendiente del bloque de intentos.
- Repetir una transición al mismo estado no borra ni duplica contenido. PUBLICADO vuelve a validar la publicación.
- Un contexto finalizado/cancelado/archivado no es editable por 010; no se fuerza su reapertura para archivar una actividad individual.

`eliminar_actividad` borra primero opciones, después preguntas y finalmente la actividad en una transacción. Un trigger nuevo rechaza también DELETE directo de actividad que no sea BORRADOR sin intentos.

**Compatibilidad administrativa:** no se reescribieron los triggers históricos de 003 ni se impuso una nueva restricción retroactiva de edición de campos de actividad publicada sin intentos. El bloqueo editorial completo de esos campos se aplica en las funciones 010; scripts de mantenimiento con permisos administrativos conservan su capacidad anterior. La escritura directa del backend sigue sin concederse. Las preguntas/opciones y el contenido con intentos conservan sus protecciones previas para todas las escrituras. La primera clasificación administrativa de contenido antiguo con intentos y dificultad NULL continúa según 009; no existe una operación editorial para saltarse su historial.

## Publicación

`publicar_actividad` y `cambiar_estado_actividad(...,'PUBLICADO')` comprueban:

1. Actor y contexto autorizados; módulo y tema PUBLICADOS.
2. Dificultad definida. Esto es requisito de la interfaz nueva, no un backfill obligatorio del contenido legado.
3. La disponibilidad no terminó; se permite programar un inicio futuro.
4. Una o más preguntas; puntaje total positivo y representable en NUMERIC(10,2), hasta 99999999.99.
5. Dos o más opciones por pregunta.
6. Selección única: exactamente una correcta. Selección múltiple: al menos dos correctas.

No se exige una incorrecta en selección múltiple: conserva la regla existente. Un error deja la actividad en su estado anterior y no publica parcialmente. El trigger de 003 vuelve a validar el cuestionario.

## Preguntas y opciones

Las operaciones de gestión consultan primero el padre autorizado. No permiten mover una pregunta a otra actividad ni una opción a otra pregunta. Los nombres de funciones y parámetros están en FIRMAS_010.md.

Pregunta: enunciado no vacío, tipo SELECCION_UNICA/SELECCION_MULTIPLE, orden INTEGER positivo, puntaje NUMERIC positivo y representable a dos decimales, explicación NULL o TEXT no vacío. El puntaje se redondea a dos decimales; se rechaza si queda cero. No admite NaN o infinitos.

Opción: texto no vacío, orden INTEGER positivo y es_correcta BOOLEAN obligatorio. Durante la edición puede haber temporalmente una clave incompleta; la publicación comprueba su consistencia.

Eliminar pregunta incluye sus opciones. Eliminar opción no elimina pregunta. Ambas operaciones solo permiten BORRADOR sin intentos. Los órdenes son únicos por padre y los conflictos producen 23505.

`reordenar_preguntas(actor,actividad,ids)` y `reordenar_opciones(actor,pregunta,ids)` reciben un INTEGER[] unidimensional con **todos** los IDs de ese padre, sin NULL, repetidos o ajenos. Se asignan órdenes 1..N en el orden del arreglo. Vacío es válido solo si el padre no tiene hijos. Se usan órdenes temporales mayores al máximo existente para no colisionar con UNIQUE; si máximo+N supera INTEGER se rechaza 22023 sin cambios. No se realiza un intercambio mediante dos actualizaciones independientes desde backend.

## Copia

`duplicar_actividad(actor,origen,seccion_destino,tema_destino,titulo_nuevo,desde,hasta)` exige permiso tanto en origen como destino. Copia instrucciones, finalidad, nivel, configuración, preguntas, explicaciones y opciones con IDs nuevos, en BORRADOR. No copia intentos, respuestas, notas o la autoría anterior. El destino puede ser otro contexto que el actor esté autorizado a gestionar, siempre que su propia sección y tema pertenezcan al mismo curso.

La copia es una nueva versión independiente, sin vínculo formal de versionado. Si se duplica contenido legado sin nivel, la copia debe clasificarse antes de publicarse. No cambia la referencia ni el historial de la actividad original.

## Lecturas y datos sensibles

- listar_actividades_gestion y obtener_actividad_gestion: fila public.actividades, incluida dificultad.
- listar/obtener preguntas: fila public.preguntas, incluida explicación.
- listar/obtener opciones: fila public.opciones_respuestas, incluida es_correcta, **solo tras autorización editorial**.
- Son funciones VOLATILE porque toman bloqueos; no ejecutarlas en transacciones READ ONLY ni mantener la transacción abierta mientras se edita desde la interfaz.
- Las lecturas del estudiante permanecen en 007 y no reciben es_correcta. No reutilizar DTOs editoriales en endpoints del estudiante.
- plataforma_backend no obtiene SELECT directo de es_correcta ni escrituras directas; la función editorial autorizada es el único acceso nuevo.

El rol compartido ya tenía lecturas académicas amplias; esta migración no introduce RLS ni intenta convertir la conexión en una identidad individual. Los privilegios manuales/heredados de un servidor deben auditarse aparte: no es un script de reinicio total de permisos.

## Errores y transacciones

| SQLSTATE | Significado del contrato nuevo |
|---|---|
| 22023 | Parámetros/configuración/permutación inválidos |
| 42501 | Cuenta, rol o asignación sin autorización |
| P0002 | Recurso no disponible/eliminado |
| 55000 | Estado, dependencia, cuestionario o contexto incompatible |
| 23505 | Orden duplicado |
| 25000 | Aislamiento diferente de READ COMMITTED |

No se cambia globalmente P0001 de 003. Pueden propagarse errores de FK/CHECK de las protecciones previas o del servidor. El backend debe mapear códigos a mensajes HTTP apropiados sin usar el texto como contrato.

Cada llamada es atómica. Para crear actividad + preguntas + opciones como una sola operación de API, usar una transacción en **el mismo cliente del pool**; comprobar errores y ejecutar ROLLBACK antes de liberarlo. También puede guardarse un BORRADOR por pasos independientes. Publicar solamente cuando esté completo.

Las modificaciones bloquean primero la actividad, luego el contexto académico, cuenta/roles y asignaciones; las creaciones bloquean el contexto antes de insertar su nueva actividad. Los hijos se cambian bajo bloqueo de su actividad. Lecturas editoriales usan FOR SHARE. Las carreras comprobadas están en el reporte; no se declara que todo posible deadlock del sistema esté descartado. Si una transacción externa mezcla varios agregados, debe respetar el orden, ser corta y gestionar reintentos completos ante 40P01/40001 cuando sea seguro.

## Ejemplo SQL parametrizado para backend

```javascript
const client = await pool.connect();
try {
  await client.query('BEGIN'); // READ COMMITTED
  const { rows: [a] } = await client.query(
    'SELECT * FROM public.crear_actividad($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)',
    [actorIdDelJWT, seccionId, temaId, titulo, instrucciones,
     'PRACTICA', 'BAJA', 3, 30, disponibleDesdeISO, disponibleHastaISO]
  );
  const { rows: [p] } = await client.query(
    'SELECT * FROM public.crear_pregunta($1,$2,$3,$4,$5,$6,$7)',
    [actorIdDelJWT, a.id, enunciado, 'SELECCION_UNICA', 1, 10, null]
  );
  await client.query('SELECT public.crear_opcion_respuesta($1,$2,$3,$4,$5)',
    [actorIdDelJWT, p.id, 'Opción A', 1, true]);
  await client.query('SELECT public.crear_opcion_respuesta($1,$2,$3,$4,$5)',
    [actorIdDelJWT, p.id, 'Opción B', 2, false]);
  // Opcional: publicar aquí si la intención de la solicitud es publicar.
  await client.query('COMMIT');
} catch (err) {
  await client.query('ROLLBACK');
  throw err;
} finally {
  client.release();
}
```

Usar Number con control de rango para NUMERIC al construir DTOs; no usar parseInt para puntajes. Fechas HTTP en ISO 8601 con zona. Mantener BIGINT/NUMERIC y NULL según el diccionario; no confundir NULL sin límite con cero. Los cuerpos de solicitudes editoriales nunca deben permitir creado_por, estado arbitrario en crear, puntajes obtenidos o actor elegido por el cliente.

## Pendientes ajenos a este bloque

No se implementan todavía administración pública de usuarios/roles, asignación de editores/docentes, CRUD de ediciones/secciones, retiro/cierre de inscripción, barrido de intentos ni unificación de métricas. El seed prepara sus relaciones como administrador hasta que existan esos bloques. No se modifican Node, React o Python, y no se declara integración HTTP de gestión editorial.

Para agentes de IA: preservar 003–009, seguir esta ampliación autorizada del alcance, no elevar permisos para resolver errores y no confundir el seed con el CRUD. Probar con plataforma_backend, usando la doble asignación docente, y mantener separados los contratos editorial y estudiante.
