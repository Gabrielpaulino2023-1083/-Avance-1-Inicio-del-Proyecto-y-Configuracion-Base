# Lectura de contenido para estudiantes — migración 007

Preparado el 13 de noviembre de 2026 sobre `main` en `80815b2e47b4b397ad990967b66fce5a52b7a71a`.
Backend de referencia: `feature/backend-plataforma`, commit `16984a5`.

## Alcance y compatibilidad

Agrega cuatro funciones públicas de lectura y un helper privado. No cambia tablas,
columnas, restricciones, triggers, firmas ni permisos de ejecución de 001–006.
No modifica `resultados_actividades`. No crea usuarios ni cambia contraseñas.
Las funciones administrativas de 006 siguen reservadas al administrador o docente editor.
Estas funciones nuevas representan la lectura del estudiante matriculado, no una
consulta pública para cualquier usuario autenticado.

El seed ampliado (varios temas, SQL JOIN y fechas históricas), las consultas del
Dashboard, el historial de recomendaciones y el listado de cursos administrables
quedan pendientes en bloques separados. Aquí no se crean endpoints Express.

## Instalación y prueba local

Requisitos: PostgreSQL con migraciones 001–006 y `database/security/001_roles_permisos.sql`
ya aplicadas. Ejecutar como propietario/administrador de la BD, habitualmente `postgres`.
El backend conserva `DB_USER=plataforma_backend`; nunca cambiarlo a `postgres` para eludir un error.

Desde la raíz del repositorio en PowerShell:

```powershell
psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -f database/migrations/007_lectura_contenido_estudiantes.sql
```

Solo si termina en `COMMIT`, ejecutar:

```powershell
psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -f database/test/pruebas_migracion_007.sql
```

La migración se aplica una vez: usa `CREATE FUNCTION`, para detectar una instalación
previa en vez de reemplazar silenciosamente funciones. Ante un fallo, su transacción
se revierte; revisar la causa antes de reintentar. No volver a ejecutar 001–006 en una BD ya instalada.

Las pruebas sí son repetibles. No requieren seeds: crean datos temporales dentro de
una transacción y terminan en `ROLLBACK`. Las secuencias pueden avanzar. Éxito esperado:
72 avisos `OK 007`, `PRUEBAS 007 COMPLETADAS` y `ROLLBACK`.
En una sesión interactiva interrumpida, ejecutar `ROLLBACK` antes de continuar.

Los archivos SQL están en UTF-8. El script de pruebas fija la codificación de cliente.

## Autorización común

1. `p_actor_id` debe proceder del JWT verificado, no del body ni de un ID de usuario enviado por el navegador.
2. La cuenta y su asignación de rol `ESTUDIANTE` deben estar activas.
3. Debe existir una inscripción `ACTIVA` del actor en el curso/contexto solicitado.
4. El curso debe estar `ACTIVO`; sección y edición no pueden estar `CANCELADA`.
5. Módulos y temas solo se exponen en `PUBLICADO`, incluyendo sus padres.

No se utiliza la ventana de inscripción para impedir a un estudiante ya inscrito
leer contenido. Una sección `CERRADA` no equivale a `CANCELADA`; se permite su lectura
si la inscripción sigue activa. No se cambia automáticamente ninguna inscripción
al terminar las fechas de edición. Este bloque no ofrece lectura histórica para
inscripciones completadas/retiradas ni para cursos archivados; eso pertenece a resultados.

Si el actor es administrador/docente sin rol ESTUDIANTE activo e inscripción propia,
debe usar las funciones administrativas existentes. Una asignación como docente de
sección o editor del curso no sustituye la inscripción para esta interfaz de estudiante.

Las lecturas son `STABLE`, con la misma instantánea que la sentencia que las invoca;
no bloquean filas ni escriben datos. Usar transacciones cortas y el aislamiento
predeterminado READ COMMITTED para ver revocaciones confirmadas en la siguiente sentencia.
No se promete revocación a mitad de una consulta ya iniciada ni dentro de una
instantánea antigua de REPEATABLE READ.

## Funciones y datos devueltos

Todos los identificadores de entrada son INTEGER positivos y obligatorios en las cuatro funciones públicas.

### 1. Módulos del curso

```sql
SELECT * FROM public.listar_modulos_publicados_estudiante($1, $2);
-- $1 actor; $2 curso
```

Devuelve una fila por módulo publicado, ordenada por `orden, id`:

| Campo | Tipo PostgreSQL |
|---|---|
| id, curso_id, orden | INTEGER |
| nombre, descripcion | TEXT |
| estado | VARCHAR(50), siempre PUBLICADO |
| actualizado_en | TIMESTAMPTZ |
| total_temas | BIGINT, solo temas PUBLICADOS |

Un módulo publicado sin temas tiene `total_temas=0`. Varias inscripciones activas
del mismo usuario en distintas ediciones del curso no duplican los módulos.
El contador administrativo de 006 conserva su significado: todos los temas.

### 2. Temas del módulo

```sql
SELECT * FROM public.listar_temas_publicados_estudiante($1, $2);
-- $1 actor; $2 modulo
```

Campos: `id INTEGER`, `modulo_id INTEGER`, `nombre TEXT`, `descripcion TEXT`,
`orden INTEGER`, `estado VARCHAR(50)`, `actualizado_en TIMESTAMPTZ`.
Orden `orden, id`. Módulo publicado sin temas publicados devuelve cero filas.
Un padre oculto/no disponible produce `P0002`, no revela sus temas.

### 3. Actividades del tema en una inscripción

```sql
SELECT * FROM public.listar_actividades_publicadas_estudiante($1, $2, $3);
-- $1 actor; $2 inscripcion; $3 tema
```

Una fila por actividad publicada de la sección exacta de esa inscripción:

| Campo | Tipo PostgreSQL |
|---|---|
| id, seccion_id, tema_id | INTEGER |
| titulo, finalidad, metodo_calificacion | TEXT |
| max_intentos, duracion_minutos | INTEGER, pueden ser NULL |
| disponible_desde | TIMESTAMPTZ |
| disponible_hasta | TIMESTAMPTZ, puede ser NULL |
| estado | VARCHAR(50), PUBLICADO |
| disponible_ahora | BOOLEAN |

La inscripción es obligatoria: usar solo `tema_id` o su nombre mezclaría secciones
y ediciones. Un tema válido sin actividades para esa sección devuelve cero filas.
Orden por `disponible_desde, id`.

Se permiten metadatos de actividades futuras o cerradas para informar su calendario.
`disponible_ahora` significa `desde <= instante < hasta` (sin límite superior cuando
`hasta IS NULL`). No significa que pueda iniciar: el máximo de intentos y la ausencia
de otro intento abierto se validan en `iniciar_intento`. No devuelve preguntas,
opciones ni instrucciones en este listado. No incluye borradores ni archivadas.

### 4. Cuestionario de un intento

```sql
SELECT * FROM public.obtener_cuestionario_estudiante($1, $2);
-- $1 actor; $2 intento
```

Requiere intento propio `EN_CURSO`, su inscripción activa, padres y actividad publicados,
ventana de disponibilidad vigente y plazo del intento no vencido. No crea intentos.
Devuelve una fila por pregunta, en orden `orden, pregunta_id`:

| Campo | Tipo PostgreSQL |
|---|---|
| intento_id, actividad_id, pregunta_id, respuesta_id, orden | INTEGER |
| instrucciones, enunciado, tipo | TEXT |
| vence_en | TIMESTAMPTZ, puede ser NULL |
| puntaje_maximo | NUMERIC(10,2), valor de la pregunta, no nota obtenida |
| opciones | JSONB, arreglo ordenado de objetos con solo id, texto y orden |
| opciones_seleccionadas | INTEGER[], inicialmente vacío |

El `respuesta_id` fue creado por `iniciar_intento` y se utiliza al guardar selecciones.
Las selecciones devueltas son las propias del intento, útiles al recargar la pantalla;
no indican si son correctas. No se exponen `es_correcta`, `explicacion`,
`puntaje_obtenido`, claves de corrección ni datos de otro intento.
Instrucciones/plazo se repiten por pregunta para mantener un retorno tabular sencillo.
Un intento con preguntas sin registros de respuesta produce `55000` para evitar
entregar silenciosamente un cuestionario incompleto.

La revisión de preguntas después de entregar/calificar es una funcionalidad posterior,
con reglas propias; este endpoint no debe reutilizarse para revelar soluciones al finalizar.

## Flujo con el backend existente

1. Obtener una inscripción del usuario (su ID y sección) desde sus cursos inscritos.
2. Consultar módulos, temas y actividades mediante las funciones de 007.
3. En una misma conexión y transacción, iniciar el intento con la función de 003 y
   obtener su cuestionario con 007. Si falla cualquiera, hacer ROLLBACK.
4. Guardar selecciones con la función existente, que verifica propiedad y plazo.
5. Entregar/calificar mediante el flujo existente. 007 no cambia estas operaciones.

Ejemplo de inicio, para adaptar al servicio Express (no es un endpoint ya implementado):

```javascript
const actorId = req.user.id; // establecido por autenticación verificada
const client = await pool.connect();
try {
  await client.query('BEGIN');
  const { rows: inicio } = await client.query(
    'SELECT public.iniciar_intento($1, $2, $3) AS intento_id',
    [actividadId, inscripcionId, actorId]
  );
  const intentoId = inicio[0].intento_id;
  const { rows: preguntas } = await client.query(
    'SELECT * FROM public.obtener_cuestionario_estudiante($1, $2)',
    [actorId, intentoId]
  );
  await client.query('COMMIT');
  // Construir DTO con intentoId y preguntas; no consultar respuestas correctas.
} catch (error) {
  await client.query('ROLLBACK');
  throw error;
} finally {
  client.release();
}
```

La lectura del cuestionario revalida publicación de padres y contexto académico;
la función antigua de inicio no incorpora todas esas comprobaciones. Este bloque
no cambia la firma ni las reglas de 003. No confirmar el inicio antes de comprobar
el cuestionario si se pretende que ambos sean una única operación del endpoint.
Para retomar un intento propio ya abierto, consultar su cuestionario; no volver a iniciarlo.
No crear un intento automáticamente con un GET, ya que consume una oportunidad.

Guardar y entregar conservan este orden de parámetros (distinto de las lecturas):

```sql
SELECT public.guardar_opciones_respuesta($1, $2, $3::INTEGER[]);
-- respuesta_id, actor del JWT, opciones seleccionadas
SELECT public.entregar_intento($1, $2);
-- intento_id, actor del JWT
```

Node `pg` puede devolver BIGINT y NUMERIC como cadenas. Convertir explícitamente
`total_temas` y `puntaje_maximo` en el DTO si el frontend espera números; conservar
NULL y arreglos vacíos. JSONB se devuelve como estructura JSON. Los DTO administrativos
existentes de módulos/temas ya utilizan los campos de lectura aquí expuestos.

Las rutas de módulos/temas pueden elegir 006 para gestión administrativa y 007 para
contenido estudiantil. No resolver el 42501 quitando la autorización de 006. La UI
de estudiante no debe habilitar acciones de creación/edición/eliminación.

## Errores para los endpoints

| SQLSTATE | HTTP sugerido | Significado en estas funciones |
|---|---|---|
| 22023 | 400 | Identificador nulo/no positivo |
| 42501 | 403 | Cuenta, rol, inscripción o contexto no autorizado |
| P0002 | 404 | Módulo/tema/intento inexistente o contenido no disponible |
| 55000 | 409 | Intento cerrado/vencido/fuera de ventana o cuestionario inconsistente |

Un error 42501 también puede ser de permisos SQL mal instalados; conservar logs
internos para distinguirlo del rechazo de negocio. No publicar stack traces al cliente.
No sustituir una lista vacía válida por un error 404.

## Permisos y límite de confianza

Las cuatro funciones son SECURITY DEFINER, propiedad del rol NOLOGIN
`plataforma_operaciones`, con `search_path=pg_catalog, public, pg_temp` y referencias
calificadas. Solo `plataforma_backend` recibe EXECUTE; PUBLIC no lo recibe. El helper
`validar_lectura_estudiante` no puede invocarse directamente desde el backend.

Las credenciales SQL son exclusivas del servidor. La BD recibe `p_actor_id` del
backend; no verifica un JWT ni deduce al usuario final a partir del login SQL compartido.
Un proceso con las credenciales del backend puede proporcionar otros IDs: por ello
esta interfaz no sustituye la autenticación y autorización de Express.

Se preservan los permisos SELECT directos existentes de security/001 por compatibilidad.
En particular, 007 no es RLS ni impide todas las consultas arbitrarias del backend.
La garantía de exclusión de soluciones se aplica al retorno explícito de estas funciones.
No usar `SELECT * FROM preguntas` ni incorporar `explicacion` en respuestas para estudiantes.

## Instrucciones para agentes de IA y desarrolladores

- No modificar 001–006 ni el script de seguridad ya aplicado para integrar 007.
- No dar al estudiante permisos administrativos ni ampliar las escrituras directas del backend.
- No reemplazar una inscripción por otra del mismo curso; conservar su ID en cada actividad/intento.
- No usar IDs fijos, nombres de temas como identidad, credenciales SQL en el frontend ni actor del body.
- No añadir respuestas correctas al DTO para que el navegador califique; usar calificación del servidor.
- No interpretar `disponible_ahora` como autorización definitiva para iniciar.
- No añadir tablas de progreso, navegación o recomendaciones como parte de esta migración.
- Ejecutar pruebas como administrador: el script cambia explícitamente al rol backend para probar permisos.
- Tras la validación local, enlazar este documento desde README y contrato; coordinar las nuevas rutas
  con backend/frontend. Las firmas existentes no cambiaron, las nuevas se documentan arriba.

## Alcance de las pruebas

Las 72 comprobaciones cubren permisos, helper privado, publicación y conteos, cuenta/rol,
inscripción y contexto, aislamiento de secciones/ediciones, argumentos inválidos, metadatos
fuera de ventana, lectura del cuestionario real creado por 003, persistencia de selecciones,
exclusión de campos de corrección, vencimiento, entrega y calificación.
El archivo es autónomo, no usa IDs existentes y revierte sus datos.
No sustituye pruebas HTTP, frontend, carga ni concurrencia entre varias sesiones.
