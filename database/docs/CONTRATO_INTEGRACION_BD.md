# Contrato vigente de integración BD — consolidación 010/011

Este documento organiza el contrato SQL disponible hasta 011 y enlaza los detalles por bloque. Base de revisión: main a8accad8f494c5050564e9dbd97535479e98d407 más las entregas locales 010/011. No afirma que esos archivos ya estén publicados o instalados en el servidor del equipo.

**Validación:** Jeison confirmó pruebas funcionales 010/011 y ambas suites concurrentes corregidas en Windows. Se conservan las evidencias nativas del asistente y la confirmación local por separado. La integración HTTP nueva y el cierre del registro directo siguen pendientes.

## 1. Fuentes y uso

Migraciones y seguridad son la fuente del esquema. Usar estas guías para las firmas y reglas:

| Bloque | Contrato |
|---|---|
| Cursos 005 | CRUD_CURSOS_AVANCE_3.md |
| Módulos/temas 006 | CRUD_MODULOS_TEMAS_AVANCE_3.md |
| Lectura estudiante 007 | LECTURA_ESTUDIANTES_007.md |
| Resultados/progreso/motor 008 | CONSULTAS_INTEGRACION_008.md |
| Dificultad/candidatas 009 | DIFICULTAD_ACTIVIDADES_009.md |
| Gestión editorial 010 | GESTION_CUESTIONARIOS_010.md y FIRMAS_010.md |
| Identidad 011 | USUARIOS_ROLES_011.md y FIRMAS_USUARIOS_011.md |

El documento histórico 009 conserva antecedentes y algunas notas ya superadas. No usarlo para determinar qué sigue pendiente. Los ejemplos de endpoints son responsabilidad del backend: una función SQL no crea una ruta HTTP.

## 2. Modelo y contexto

Usuarios → roles mediante usuario_roles. Cursos → ediciones → secciones → inscripciones. Cursos → módulos → temas. Cada actividad pertenece a un tema y a una sección del mismo curso. Intentos pertenecen a una actividad y una inscripción de su sección; respuestas y selecciones pertenecen al intento.

Módulos/temas son contenido común del curso; actividades son contenido de sección. Una asignación de editor de curso no equivale a una inscripción estudiantil ni a asignación docente de todas sus secciones.

No trasladar padres académicos ni contenido con historial. No crear otra inscripción para simular un traslado: aún debe implementarse el contrato de esa operación.

## 3. Actores y permisos

| Operación | ADMINISTRADOR activo | DOCENTE activo | ESTUDIANTE activo |
|---|---|---|---|
| Crear/editar cursos | Sí, según 005 | No | No |
| Gestionar módulos/temas | Sí | Editor activo del curso | No |
| Gestionar actividades/preguntas/opciones 010 | Contexto editable | Editor del curso + docente de sección activos | No |
| Leer claves editoriales 010 | Autorizado | Mismo alcance editorial | No |
| Leer/responder contenido estudiante 007 | No por ser administrador | No por ser docente | Inscripción propia ACTIVA y contexto publicado/autorizado |
| Administrar usuarios/roles 011 | Sí, con protecciones | No | No |
| Consultar/editar perfil propio 011 | Sí | Sí | Sí |
| Inscribirse por cuenta propia 004 | Solo con rol estudiante y sus reglas | No por ser docente | Sí, con cupo/ventana/contexto válidos |

Roles múltiples compatibles: ADMINISTRADOR+ESTUDIANTE o ADMINISTRADOR+DOCENTE. 011 prohíbe ESTUDIANTE+DOCENTE activos. El rol principal sigue ADMINISTRADOR > DOCENTE > ESTUDIANTE; la interfaz actual no recibe por ello un selector de rol automáticamente.

Cada llamada recibe actor del JWT verificado, nunca elegido por el cliente. La autorización se valida también en SQL. Backend debe comprobar estado/roles actuales al autorizar peticiones: un JWT firmado conserva claims hasta expirar si no existe una comprobación adicional.

## 4. Operaciones académicas existentes

- inscribir_estudiante(seccion,estudiante,actor): autónoma para sí mismo o administrativa; cuenta y rol activos, curso ACTIVO, edición ABIERTA, sección ABIERTA, ventana válida, inscripción única por edición y cupo bajo bloqueo. READ COMMITTED. No define retiro/traslado/cierre administrativo completo.
- iniciar_intento(actividad,inscripcion,estudiante): crea intento y respuestas vacías; valida propiedad, sección, cuenta/rol, estado de actividad, disponibilidad, límite y ausencia de otro EN_CURSO. El endurecimiento del contexto académico completo en esta operación autónoma sigue pendiente de revisión; no confundirlo con la validación más amplia de 007.
- guardar_opciones_respuesta(respuesta,estudiante,opciones INTEGER[]): reemplaza selección; arreglo vacío la limpia. Sin NULL/repetidos, opciones de la pregunta y selección única compatible; intento EN_CURSO dentro del plazo.
- entregar_intento(intento,estudiante): conserva entrega previa; estado ENTREGADO, motivo MANUAL o VENCIMIENTO. Invocarla es necesario: no existe un trigger de reloj que cierre abandonos.
- calificar_intento(intento): solo entregado; suma por coincidencia exacta del conjunto de opciones. Sin crédito parcial. Repetir calificación conserva nota/fecha. La función histórica no recibe actor: backend verifica propiedad por entrega antes de llamarla. No exponerla como endpoint de calificación arbitraria.

Entregar y calificar se deben ejecutar en una transacción del mismo cliente. Inicio + lectura de cuestionario también usan una transacción para revertir si el contexto no permite obtener el cuestionario. No mantener transacciones abiertas durante la interacción humana o la ejecución del motor.

## 5. Gestión editorial 010

Creación siempre BORRADOR. Se permite preparar un cuestionario incompleto por pasos. Modificar configuración/hijos solo en BORRADOR sin intentos mediante la interfaz nueva. Publicar requiere dificultad, padres publicados, ventana no terminada, preguntas, opciones/claves válidas y puntaje total representable.

Con intentos no se vuelve a BORRADOR ni se cambia contenido/configuración protegida. Archivar no borra historia y se rechaza con EN_CURSO. Para otra versión, duplicar: copia profunda de preguntas/opciones con nuevos IDs; sin intentos ni notas. No es un sistema formal de versionado.

Eliminar físicamente solo BORRADOR sin intentos, con hijos eliminados de forma controlada. El trigger nuevo protege DELETE de actividad. Las protecciones previas de 003/009 siguen vigentes. La restricción completa de configuración publicada sin intentos se aplica a la interfaz 010; scripts administrativos conservan las capacidades históricas descritas en su guía. No describirla como una nueva prohibición global retroactiva.

Lecturas editoriales pueden devolver es_correcta después de autorizar al actor. El cuestionario del estudiante de 007 conserva su contrato sin esa columna. No reutilizar DTOs editoriales en rutas estudiantiles.

## 6. Identidad 011 y transición

Registrar públicamente siempre ESTUDIANTE, sin parámetro rol. Hash bcrypt generado en backend; ficha segura sin hash. Crear/listar/editar/bloquear usuarios y administrar roles requiere administrador activo; el perfil propio permite nombre/apellido, no asignarse roles o estado.

Cambio académico atómico ESTUDIANTE ↔ DOCENTE, conservando ADMINISTRADOR. Retirar ESTUDIANTE se rechaza con un intento EN_CURSO. Retirar DOCENTE mediante la función revoca editores/asignaciones; reactivar el rol no las reactiva. Suspender la cuenta es reversible, conserva asignaciones e historial y puede hacerse aunque tenga un intento abierto; no calcula una nota ni cierra ese intento automáticamente.

El último administrador efectivo no puede ser desactivado o eliminado, ni retirarse su rol. Los triggers serializan escrituras de usuarios/roles con un cerrojo transaccional global y requieren READ COMMITTED. Transacciones cortas y hashing antes de abrirlas. No se crean cuentas administrativas por un registro público con rol elegido.

**Fase A:** 011 mantiene el registro SQL directo limitado del backend actual para compatibilidad. El backend sigue fijando ESTUDIANTE en ese camino antiguo; no afirmar que cualquier INSERT arbitrario está restringido a ese rol.

**Fase B:** Porfirio cambia userModel.create a registrar_estudiante, prueba registro/login y luego se ejecuta security/002_cerrar_registro_directo.sql con confirmación explícita. Solo entonces se retiran esos INSERT. El script no forma parte de instalar_revision_011.sql. No ejecutarlo ahora por disponer del archivo.

Cambiar hash no invalida automáticamente JWT anteriores. Los flujos de verificación de contraseña, recuperación o invalidación de sesiones corresponden al contrato de autenticación del backend; no se implementa recuperación por correo en este paquete.

## 7. Resultados, progreso y motor

Calificación por PROMEDIO de intentos CALIFICADOS. PRACTICA participa en estadísticas, pero no aporta nota_academica_porcentaje. Sin calificados: promedio NULL; sin intentos: la vista resultados_actividades no tiene fila. Para listados completos usar 008, que incluye actividades sin intentos según sus reglas.

Progreso por tema: todas sus actividades publicadas tienen al menos un intento calificado. No significa que se hayan aprobado ni que se domine el tema; un tema sin actividades no se marca completo. El progreso es calculado, sin snapshots semanales.

Minutos: duración entre inicio y entrega del intento, aproximación al estudio; no tiempo observado de atención. Fechas agregadas en America/Santo_Domingo. La consulta de intervalo diario usa fin exclusivo; preservar NULL y zona horaria en DTOs.

Interacciones del motor: una fila por intento calificado propio del tema/inscripción, score_percentage, errors (respuestas con puntaje cero), attempts (número secuencial), repetitions=attempts-1, navigation_count=0 y study_minutes. No afirmar medición de navegación ni uso de tiempo en las reglas del motor. El motor se presenta basado en reglas.

La recomendación por intentos y el dominio mostrado como promedio por actividad no son automáticamente equivalentes. Definir un cálculo único o etiquetas explícitas con backend/frontend antes de afirmar que sus porcentajes deben coincidir. No alterar notas para igualar tarjetas.

009: dificultad absoluta BAJA/MEDIA/ALTA; NULL significa legado sin clasificar. reduced/current/increased es un ajuste relativo a la referencia, no una equivalencia fija con esos niveles. Candidatas del mismo tema/sección y contexto, publicadas, clasificadas, disponibles, con intentos restantes y sin EN_CURSO propio. Sin referencia clasificada o candidata, conservar recomendación del tema. Consultar no reserva ni inicia un intento; iniciar revalida disponibilidad.

## 8. PostgreSQL, errores y tipos

Cuenta Express: plataforma_backend. Propietario operativo: plataforma_operaciones NOLOGIN, sin membresía del backend. Cuenta instaladora administrativa separada. Funciones SECURITY DEFINER, objetos cualificados y search_path fijo. Auxiliares privados sin EXECUTE para PUBLIC/backend. No conceder escrituras directas ni SELECT directo de es_correcta para resolver una ruta faltante.

No hay RLS. El rol compartido tiene lecturas académicas y de autenticación necesarias para el código actual; una función que recibe actor no valida JWT por sí misma. No permitir SQL arbitrario desde el cliente.

| Tipo / código | Tratamiento |
|---|---|
| INTEGER | IDs positivos; no fijarlos a un seed |
| NUMERIC y BIGINT | pg suele devolver strings; convertir con control de rango y precisión |
| NULL | Dato ausente/sin límite según campo; no convertir indiscriminadamente a cero |
| TIMESTAMPTZ | ISO 8601 con zona en HTTP |
| 22023 / 42501 / P0002 | Argumento inválido / sin autorización / recurso no disponible |
| 55000 / 23505 | Estado/dependencia incompatible / unicidad |
| 25000 | Aislamiento incompatible con la operación |
| P0001 | Reglas históricas de 003/004; no cambiar códigos anteriores sin migración y coordinación |

No basar contratos nuevos en el texto exacto de errores. Toda llamada fallida dentro de una transacción necesita ROLLBACK antes de devolver la conexión al pool. Si se admite reintento por 40P01/40001, repetir la transacción completa de forma segura, no una sentencia suelta.

## 9. Instalación, datos y restauración

Orden: 001–003, seguridad 001, 004–011. No ejecutar todos los migrations antes de seguridad. El instalador de revisión es exclusivo de bases nuevas; las bases existentes reciben solo lo pendiente y respaldado. Cada computadora/servidor debe aplicar su SQL: el merge no lo hace.

Los seeds demo son de desarrollo y no se ejecutan al arrancar Express. Reutilizan cuentas según sus instrucciones y no deben tratarse como reinicio de credenciales o notas. Las pruebas concurrentes requieren bases independientes por versión; usar el lanzador corregido y nunca deshabilitar triggers para limpiar la 011.

Base central, acceso por red privada, selección de datos oficiales y restauración completa siguen pendientes. Un respaldo no certifica recuperación hasta restaurarlo y comprobar roles, propietarios, SECURITY DEFINER, secuencias, datos y uso con plataforma_backend. pg_dump no crea por sí solo los roles globales del servidor.

## 10. Instrucciones para agentes de IA y cierre

- Leer las firmas y la guía del bloque antes de proponer SQL o un endpoint.
- Preservar historial y funciones anteriores; usar cambios incrementales.
- No confundir usuario ADMINISTRADOR de la aplicación con postgres.
- No exponer claves/hash, aceptar actor del body, alterar notas desde frontend o elevar privilegios del backend.
- Distinguir SQL implementado, pruebas nativas, confirmación Windows e integración HTTP.
- Mantener separado el cierre opcional de registro; coordinar revalidación de identidad en JWT.
- No declarar la BD v1 completa: faltan bloques de ciclo académico/asignaciones, intentos, métricas y operación central descritos en MATRIZ_CIERRE_BD_V1.md.

[Estado y evidencias de esta entrega](ENTREGA_010_011.md). [Diccionario de datos](DICCIONARIO_DATOS_BD.md).
