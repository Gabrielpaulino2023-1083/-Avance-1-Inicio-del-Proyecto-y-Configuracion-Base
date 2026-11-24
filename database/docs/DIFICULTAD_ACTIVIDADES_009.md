# Dificultad y actividad sugerida — propuesta BD-009-v1

**Estado: pruebas embebidas aprobadas; instalación y pruebas en base nueva y base local confirmadas por Jeison. Pendiente de aprobación/integración del equipo.** Fecha: 22 de noviembre de 2026.
Base revisada: `main`, commit `6fe1ebdaec46536a9227f4cc1c9086aa1f74aa63`. No se ha publicado ni aplicado esta propuesta a una base compartida.

## Qué se entrega

- Migración 009: columna de dificultad, protección de su clasificación y consulta de candidatas autorizadas.
- Ejemplo JavaScript independiente para seleccionar una candidata según la salida actual del motor. No modifica Express ni Python.
- Seed separado con preguntas distintas por nivel, que usa el estudiante existente y conserva sus credenciales.
- Pruebas SQL y JavaScript, instrucciones de instalación aislada y resultados de validación.

Se conservan las firmas y definiciones de las funciones anteriores, incluidas 007 y 008. No se recalculan notas ni se cambia la recomendación del tema. La selección de una actividad es un complemento opcional. Actividades y preguntas continúan precargadas por scripts; no se agrega un CRUD docente de cuestionarios.

## Campo y reglas

| Campo | Tipo SQL | Valores | Nulabilidad / default |
|---|---|---|---|
| actividades.dificultad | TEXT | BAJA, MEDIA, ALTA | NULL permitido; sin default |

Los tres niveles son absolutos y los asigna quien prepara el contenido con un script administrativo. NULL significa **sin clasificar**. La migración deja así las actividades anteriores: no deduce su dificultad de la nota ni asigna MEDIA automáticamente. El seed nuevo sí clasifica sus actividades. Sus niveles son criterios de demostración, no niveles validados mediante un estudio pedagógico.

Antes de cualquier intento se puede cambiar o retirar la clasificación. Si una actividad antigua tiene intentos y dificultad NULL, se permite una primera clasificación explícita. Una vez tiene nivel e intentos, cambiar o retirar el nivel produce SQLSTATE `55000`; debe crearse otra actividad. Esto mantiene una referencia estable para la nueva selección, pero la clasificación inicial de contenido antiguo sigue siendo una decisión editorial.

El backend no recibe permiso nuevo de escritura directa ni de clasificación. La columna no contiene la respuesta correcta. Esta migración no introduce RLS ni elimina permisos SELECT previos del rol compartido; la autorización HTTP y el uso de las funciones siguen siendo responsabilidad del backend.

## Consulta nueva

```sql
SELECT * FROM public.listar_candidatas_actividad(
    $1::integer, -- actor obtenido del JWT verificado
    $2::integer, -- inscripcionId
    $3::integer, -- temaId
    $4::integer  -- actividad de referencia; NULL para elegir la más reciente
);
```

Firma: `listar_candidatas_actividad(integer, integer, integer, integer DEFAULT NULL)`.
Función `STABLE SECURITY DEFINER`, propietario `plataforma_operaciones`, search_path fijo. EXECUTE concedido a `plataforma_backend`, revocado a PUBLIC. Las funciones auxiliares privadas no se habilitan al backend.

Reutiliza la validación de contexto de 008: actor estudiante activo, rol activo, inscripción propia ACTIVA, curso ACTIVO y contexto de edición/sección no cancelado. Además exige tema y módulo PUBLICADOS del curso de esa inscripción.

Una candidata debe pertenecer al mismo tema **y a la sección de esa inscripción**; estar PUBLICADA y clasificada; haber alcanzado disponible_desde; no haber alcanzado disponible_hasta (si existe); tener intentos restantes, contando todos los estados; y no tener un intento propio EN_CURSO. Un intento vencido que siga EN_CURSO también la excluye hasta que se cierre mediante el flujo existente. Esta consulta no lo cierra.

| Columna devuelta | Tipo SQL | Significado |
|---|---|---|
| actividad_id, tema_id, seccion_id | INTEGER | Identificadores de la candidata |
| titulo, dificultad | TEXT | Contenido y nivel absoluto |
| intentos_iniciados | BIGINT | Todos los intentos de esa actividad e inscripción |
| max_intentos | INTEGER nullable | NULL = sin límite |
| intentos_restantes | BIGINT nullable | NULL = sin límite; siempre positivo cuando existe límite |
| disponible_desde | TIMESTAMPTZ | Inicio inclusivo de disponibilidad |
| disponible_hasta | TIMESTAMPTZ nullable | Fin exclusivo; NULL = sin cierre |
| actividad_referencia_id | INTEGER | Referencia común a todas las filas |
| dificultad_referencia | TEXT | Nivel de la referencia |
| es_repeticion | BOOLEAN | Candidata igual a la referencia |

BIGINT puede llegar como string desde `pg`. No convertir NULL de intentos_restantes a cero. Los IDs INTEGER llegan como números con los parsers habituales de `pg`; el ejemplo JS los valida. Fechas para HTTP: serializar como ISO 8601 con zona horaria.

### Referencia

Después de entregar y calificar: enviar la actividad recién calificada como cuarto argumento. Debe tener un intento CALIFICADO propio en esa inscripción y tema. Puede estar agotada o archivada: sirve como referencia aunque no pueda ser candidata.

Desde el dashboard: omitir el cuarto argumento o pasar NULL. Se toma el último intento CALIFICADO de ese tema e inscripción, por `calificado_en DESC, id DESC`. Si no hay ninguno, o esa actividad no está clasificada, se devuelven cero filas. No se busca una referencia más antigua para ocultar la falta de clasificación.

Sin candidatas se conserva la recomendación del tema. No es un error del motor ni razón para inventar una actividad. La consulta ordena por ID; **su primera fila no es la selección final**.

| Situación | Resultado |
|---|---|
| Tema / referencia con argumento no válido | 22023 |
| Contexto no autorizado / referencia sin calificación propia | 42501, según validadores |
| Tema no disponible en ese contexto | P0002 |
| Sin referencia clasificada o sin candidatas | Cero filas |

La consulta no crea, reserva ni inicia intentos. Su resultado es una fotografía de la disponibilidad. Al pulsar Iniciar, el backend debe ejecutar `iniciar_intento` y manejar nuevamente sus validaciones. Usar consultas/transacciones cortas; no mantener una transacción abierta mientras se ejecuta Python o el estudiante decide.

## Política del backend propuesta para aprobación

La salida del motor se interpreta **respecto del nivel de la referencia**:

| Nivel de referencia | reduced | current | increased |
|---|---|---|---|
| BAJA | BAJA | BAJA | MEDIA |
| MEDIA | BAJA | MEDIA | ALTA |
| ALTA | MEDIA | ALTA | ALTA |

Orden de selección determinista:

1. Preferir una actividad diferente de la referencia.
2. Entre ellas, elegir el nivel más cercano al objetivo.
3. Empate de distancia: nivel menor; después, ID menor.
4. Si únicamente queda la referencia, permitir repetirla mientras cumpla los filtros.

La preferencia por otra actividad tiene prioridad incluso sobre repetir la referencia con coincidencia exacta de nivel. Debe revisarse expresamente con el equipo. El resultado incluye `coincideNivel` para distinguir el objetivo de la dificultad realmente disponible.

Ejemplo reutilizable: [seleccion_actividad.cjs](ejemplos/seleccion_actividad.cjs).

```javascript
const { seleccionarActividad } = require('./seleccion_actividad.cjs');
const { rows } = await pool.query(
  'SELECT * FROM public.listar_candidatas_actividad($1,$2,$3,$4)',
  [actorIdDelJWT, inscripcionId, temaId, actividadReferenciaId ?? null]
);
const actividadSugerida = seleccionarActividad(rows, recommendation.dificultad);
// Añadir al DTO únicamente al acordar el contrato HTTP con frontend.
```

El backend debe validar la salida del motor y autorizar el contexto del endpoint. Un valor de ajuste desconocido falla explícitamente en el ejemplo; no debe transformarse silenciosamente en MEDIA. No tomar el actor del body. Usar inscripcionId y temaId para evitar nombres repetidos entre cursos.

DTO adicional propuesto, todavía no implementado en un endpoint:

```json
{
  "actividadSugerida": {
    "actividadId": 123,
    "titulo": "Actividad de demostración",
    "dificultad": "BAJA",
    "dificultadObjetivo": "BAJA",
    "coincideNivel": true,
    "esRepeticion": false,
    "actividadReferenciaId": 122
  }
}
```

IDs ilustrativos. Si no hay sugerencia, `actividadSugerida: null`. Mantener la recomendación del tema y los campos actuales. El frontend puede mostrar un botón para iniciar la actividad; no iniciarla automáticamente. Si no coincide el nivel, mostrar la dificultad real sin afirmar que se encontró el objetivo exacto.

El motor sigue basado en reglas; no se modifica para convertirlo en aprendizaje automático. navigation_count continúa como aproximación 0 sin medición; study_minutes no participa en sus reglas. Los tiempos derivados de intentos no equivalen a tiempo de estudio observado. No se agregan navegación ni historial de recomendaciones.

## Instalación y pruebas en Windows

Descomprimir el paquete sobre una copia actualizada del repositorio, conservando la carpeta `database/`. Revisar `git diff` antes de sustituir README, contrato o diccionario si el equipo los modificó después del commit base. Trabajar en una rama nueva, por ejemplo `feature/dificultad-actividades`.

### Opción A: instalar desde cero en una base nueva

Esta opción sirve para comprobar la instalación completa. No es necesario recrear la base habitual para usar 009. Desde la raíz del repositorio, con psql disponible:

```powershell
createdb -U postgres proyectofinal_revision_009
psql -X -U postgres -d proyectofinal_revision_009 -v ON_ERROR_STOP=1 -f database/test/instalar_revision_009.sql
# Continuar solo si terminó sin errores:
psql -X -U postgres -d proyectofinal_revision_009 -v ON_ERROR_STOP=1 -f database/test/pruebas_migracion_009.sql
node --test database/test/pruebas_seleccion_009.cjs
```

El instalador aplica 001–003, seguridad y 004–009 en ese orden, sin seeds. Rechaza una base con tablas públicas existentes. Las pruebas 009 usan fixtures propios y terminan con ROLLBACK; las secuencias pueden avanzar, como es normal en PostgreSQL. No requieren contraseñas reales ni que Express esté encendido. Las migraciones son de una sola ejecución, no son seeds idempotentes.

Para probar el seed en esa base nueva, cargar primero `datos_prueba.sql` y `datos_prueba_actividades_intentos.sql`, siguiendo sus instrucciones existentes. El segundo pide un hash bcrypt válido y crea al estudiante demo. No reutilizar los hashes ficticios de los fixtures SQL para login.

```powershell
psql -X -U postgres -d proyectofinal_revision_009 -v ON_ERROR_STOP=1 -f database/seeds/datos_prueba.sql
psql -X -U postgres -d proyectofinal_revision_009 -v ON_ERROR_STOP=1 -f database/seeds/datos_prueba_actividades_intentos.sql
# Pegar el hash bcrypt cuando lo solicite el seed anterior.
psql -X -U postgres -d proyectofinal_revision_009 -v ON_ERROR_STOP=1 -f database/seeds/datos_prueba_dificultad_009.sql
psql -X -U postgres -d proyectofinal_revision_009 -v ON_ERROR_STOP=1 -f database/test/pruebas_seed_dificultad_009.sql
```

### Opción B: actualizar la base local existente

Se puede usar la base `proyectofinal_db` con sus datos actuales. Debe tener aplicadas correctamente 001–008 y `security/001_roles_permisos.sql`. Esta actualización agrega la columna y las funciones nuevas; conserva los usuarios, inscripciones, respuestas y notas existentes. No ejecutar `instalar_revision_009.sql` ni volver a cargar las migraciones anteriores.

Ejecutar desde la raíz del repositorio, en PowerShell. Usar la cuenta administrativa que instala las migraciones (`postgres` en nuestro entorno); el backend continúa conectándose como `plataforma_backend`.

**1. Guardar una copia y comprobar el estado actual.**

```powershell
$respaldo = Join-Path $env:TEMP ("proyectofinal_pre009_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.dump')
pg_dump -U postgres -d proyectofinal_db -Fc -f $respaldo
if ($LASTEXITCODE -ne 0) { throw 'No se pudo generar el respaldo. Detener la actualización.' }
Write-Output "Respaldo: $respaldo"

psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -c "SELECT current_database(), current_user, version(); SELECT to_regprocedure('public.validar_contexto_resultados(integer,integer)') IS NOT NULL AS auxiliar_008_presente, to_regprocedure('public.listar_candidatas_actividad(integer,integer,integer,integer)') IS NOT NULL AS funcion_009_presente; SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='actividades' AND column_name='dificultad') AS columna_009_presente;"
```

El auxiliar de 008 debe estar presente. Esta comprobación identifica objetos clave; no sustituye el registro de que las migraciones anteriores se instalaron sin errores.

- Si función y columna de 009 están ausentes, continuar con el paso 2.
- Si ambas están presentes y ya completaste esta misma 009, **omitir el paso 2**. Puedes repetir sus pruebas.
- Si solo una está presente o hubo una instalación interrumpida, detenerse y revisar el error original; no borrar objetos ni intentar reinstalar automáticamente.

**2. Aplicar únicamente 009, una sola vez.**

```powershell
psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -f database/migrations/009_dificultad_candidatas.sql
if ($LASTEXITCODE -ne 0) { throw 'La migración falló. Revisar el error antes de continuar.' }
```

La migración está dentro de una transacción. No es idempotente: ejecutarla de nuevo sobre una instalación correcta produce conflicto por objetos existentes.

**3. Ejecutar las pruebas.**

```powershell
psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -f database/test/pruebas_migracion_009.sql
if ($LASTEXITCODE -ne 0) { throw 'Fallaron las pruebas SQL. Revisar antes de continuar.' }
node --test database/test/pruebas_seleccion_009.cjs
if ($LASTEXITCODE -ne 0) { throw 'Fallaron las pruebas del selector.' }
```

Los fixtures SQL terminan con ROLLBACK y no agregan usuarios ni actividades permanentes; las secuencias pueden avanzar.

**4. Cargar el escenario de demostración, si se necesita.**

Si ya existe `estudiante.demo@example.com` activo, con su rol ESTUDIANTE activo, y un administrador activo, ejecutar:

```powershell
psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -f database/seeds/datos_prueba_dificultad_009.sql
if ($LASTEXITCODE -ne 0) { throw 'El seed falló. Revisar antes de continuar.' }
psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -f database/test/pruebas_seed_dificultad_009.sql
if ($LASTEXITCODE -ne 0) { throw 'La validación del seed falló.' }
```

No es necesario volver a crear al estudiante ni generar otro hash. El seed nuevo crea un curso separado y no cambia las credenciales. Se puede omitir si solo se necesita la estructura. Su reejecución conserva el escenario existente; no lo reinicia. Si ya se consumieron intentos, su prueba inicial puede dejar de corresponder al estado actual: usar la base independiente para repetir ese escenario.

En tu caso, como ya confirmaste la ejecución correcta en la base local, no necesitas reinstalar 009. Estos pasos quedan para otros integrantes y para entornos que todavía estén en 008.

El seed acepta `-v demo_email=otro.estudiante@example.com`; debe ser un estudiante existente activo con su rol activo. Utiliza un curso demo único: no está diseñado para cargar varios estudiantes diferentes sobre el mismo curso.

## Escenario del seed

Curso `DEMO-DIFICULTAD-009`, tema `SQL JOIN (demo dificultad)`. No se cambian DEMO-003 ni DEMO-SQL-007. El nombre distinto evita colisiones con endpoints antiguos que buscan por texto.

| Actividad | Nivel | Estado inicial |
|---|---|---|
| Referencia: relacionar pedidos y clientes | MEDIA | Un intento CALIFICADO, 0/20 |
| Basico: significado de las uniones | BAJA | Sin intentos |
| Intermedio: calcular filas de una union | MEDIA | Sin intentos |
| Avanzado: agregacion y filtros de LEFT JOIN | ALTA | Sin intentos |

Cuatro actividades PUBLICADAS de PRACTICA, dos preguntas de selección única por actividad, tres opciones por pregunta; ocho preguntas y veinticuatro opciones en total. Límite de tres intentos por actividad. El intento de referencia se crea, responde, entrega y califica mediante las funciones existentes, sin falsificar fechas. Bajo la política propuesta, reduced/current/increased seleccionan respectivamente las actividades nuevas BAJA/MEDIA/ALTA.

No crea ni cambia usuarios, passwords o roles. Exige un estudiante y un administrador activos. Una segunda carga reconoce su curso y no borra el trabajo posterior del estudiante. Ante colisión o estructura incompleta rechaza reconstruir automáticamente. Las pruebas del seed describen el estado inicial: ejecutarlas antes de consumir intentos desde la interfaz.

## Qué debe revisar cada parte

- **BD:** instalación y pruebas locales confirmadas por Jeison; conservar la evidencia y abrir PR. La confirmación del responsable se distingue de las pruebas embebidas ejecutadas por el asistente.
- **Backend:** aprobar política relativa y desempates; incorporar consulta y selector; acordar DTO opcional y manejar ausencia de candidata; validar con plataforma_backend.
- **Motor:** confirmar que reduced/current/increased expresan ajuste relativo; la lógica Python actual no se cambia en este paquete.
- **Frontend:** aprobar DTO con backend, mostrar la actividad y su nivel real; mantener recomendación del tema sin candidata; reutilizar el inicio existente.
- **Equipo:** probar el recorrido completo y aprobar el PR antes de incorporarlo a la demo compartida. Si requieren ajustes, modificar esta propuesta y sus pruebas antes del merge.

Para agentes de IA: usar 009 como ampliación propuesta de 001–008; preservar las firmas anteriores; no inventar endpoints ni afirmar integración por disponer del SQL; no clasificar automáticamente el contenido antiguo; no devolver es_correcta al estudiante; no elevar plataforma_backend a superusuario; distinguir pruebas embebidas de pruebas HTTP y PostgreSQL local.
