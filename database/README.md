Base de datos — Motor de Aprendizaje Adaptativo
Este directorio contiene el esquema PostgreSQL del proyecto Motor de Aprendizaje Adaptativo Basado en Comportamiento del Estudiante, los datos ficticios de desarrollo, la configuración de acceso y las pruebas de integridad.

Estado al 2 de noviembre de 2026: se verificó la instalación desde los archivos en una base nueva y el recorrido iniciar → responder → entregar → calificar → consultar resultados, utilizando el rol limitado del backend. Además, se creó y probó localmente la migración 004 de inscripción, se cargó el seed de integración y se verificaron por HTTP el login y /api/auth/me. La integración HTTP de las operaciones académicas, el frontend y el motor Python sigue pendiente. La creación y pruebas de 004 fueron reportadas por el responsable de BD; no se ha confirmado su publicación o merge en GitHub.
1. Alcance de esta entrega
El esquema incluye 17 tablas, una vista, once funciones y nueve triggers después de aplicar 004 (sin extensiones ni objetos auxiliares):
- Usuarios, múltiples roles y asignaciones.
- Cursos, ediciones, secciones, docentes, editores e inscripciones.
- Módulos y temas compartidos entre las secciones.
- Prácticas y evaluaciones de un tema, con preguntas de selección única o múltiple.
- Intentos, respuestas y opciones seleccionadas.
- Entrega, calificación automática y promedio de los intentos calificados.
- Inscripción autónoma o administrativa mediante inscribir_estudiante(); pruebas básicas locales satisfactorias.
- Restricción de escrituras directas en resultados para el rol de conexión de Express.
Todavía no incluye tablas de contenidos, interacciones, recomendaciones o progreso. Tampoco incluye un proceso programado de cierre de intentos vencidos.
2. Archivos y orden de ejecución
Archivo	Propósito
database/migrations/001_estructura_academica_inicial.sql	Nueve tablas iniciales de identidad y organización académica.
database/migrations/002_modulos_temas.sql	Módulos y temas.
database/migrations/003_actividades_intentos_respuestas.sql	Seis tablas nuevas, funciones, triggers y vista de resultados.
database/security/001_roles_permisos.sql	Roles PostgreSQL y permisos; ejecutar después de 001–003 y antes de 004.
database/migrations/004_inscripcion_estudiantes.sql	Función de inscripción y permisos adicionales; requiere los roles del script de seguridad.
database/seeds/datos_prueba_actividades_intentos.sql	Estudiante con hash real, curso DEMO-003, actividades publicadas y resultados conocidos.
database/docs/CONTRATO_INTEGRACION_BD.md	Contrato SQL, reglas, límites y guía de integración para desarrolladores y agentes.
database/seeds/datos_prueba.sql	Usuarios, roles, curso, ediciones, secciones e inscripción ficticios.
database/seeds/datos_prueba_modulos_temas.sql	Dos módulos y cuatro temas del curso de ejemplo.
database/test/pruebas_migracion_003.sql	Pruebas consolidadas de actividades, intentos, resultados y permisos.
database/README.md	Instrucciones, reglas, evidencia y pendientes.


Los archivos deben estar incorporados físicamente al repositorio. Las pruebas anteriores de 001 y 002 pueden conservarse en su ubicación actual. Si se utilizan simultáneamente carpetas test y tests, unificar las rutas del repositorio y de su documentación; este documento usa database/test para el archivo consolidado de 003.

Los seeds y las pruebas se mantienen separados de las migraciones. No agregar pruebas temporales al archivo de creación del esquema.
3. Requisitos
- PostgreSQL en ejecución y cliente psql disponible.
- Cuenta administrativa, como postgres, para crear la base, instalar objetos y configurar roles.
- Copia local de los archivos indicados.
Registrar la versión real del entorno:
SELECT version();
No se ha establecido una versión mínima mediante pruebas en varias versiones.
4. Instalación en una base nueva
4.1 Crear una base de validación
Desde una terminal:
psql -h localhost -p 5432 -U postgres -d postgres -W
Dentro de psql, fuera de una transacción:
CREATE DATABASE proyectofinal_validacion;
\connect proyectofinal_validacion
SELECT current_database(), current_user;
Si ese nombre ya existe, revisar su contenido; no borrarlo ni repetir las migraciones sin comprobar su estado. La base habitual proyectofinal_db debe conservarse mientras se valida una instalación independiente.
4.2 Aplicar esquema y seguridad
Establecer la raíz local del repositorio. Esta ruta es un ejemplo que cada integrante debe adaptar:
\cd 'C:/ruta/al/proyecto'
Ejecutar cada archivo en orden y comprobar que termine en COMMIT sin errores:
\set ON_ERROR_STOP on
\encoding UTF8
SET search_path = public;

\i 'database/migrations/001_estructura_academica_inicial.sql'
\i 'database/migrations/002_modulos_temas.sql'
\i 'database/migrations/003_actividades_intentos_respuestas.sql'
\i 'database/security/001_roles_permisos.sql'
\i 'database/migrations/004_inscripcion_estudiantes.sql'
Las migraciones de estructura se ejecutan una sola vez por base. Si una falla dentro de su transacción, detenerse y ejecutar ROLLBACK;. Los archivos anteriores que terminaron con COMMIT siguen aplicados: no repetirlos.

El script de seguridad corregido aplica el permiso de conexión a current_database(). Los roles pertenecen al servidor PostgreSQL y pueden existir ya por pruebas en otra base. El script los reutiliza y comprueba sus atributos básicos, sin modificar sus contraseñas. No elimina permisos adicionales concedidos manualmente ni constituye una auditoría completa de membresías.
4.3 Comprobar los objetos
SELECT COUNT(*) AS tablas FROM pg_tables WHERE schemaname = 'public';
SELECT COUNT(*) AS vistas FROM pg_views WHERE schemaname = 'public';

SELECT COUNT(*) AS funciones
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public';

SELECT COUNT(*) AS triggers
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND NOT t.tgisinternal;
En una base limpia de este proyecto: 17 tablas, 1 vista, 11 funciones y 9 triggers después de 004. Antes de 004 eran 10 funciones. Estos conteos no sustituyen las pruebas funcionales.
4.4 Cargar los datos de ejemplo
Como administrador, ejecutar una sola vez:
\i 'database/seeds/datos_prueba.sql'
\i 'database/seeds/datos_prueba_modulos_temas.sql'
El segundo seed depende del primero. Si su archivo tiene otro nombre local, renombrarlo o ajustar la instrucción; un error de archivo inexistente no ejecuta su contenido. No repetir el primer seed si ya terminó en COMMIT.
Correo de ejemplo	Función
admin@example.com	Administrador inicial.
docente@example.com	Docente y editor.
estudiante@example.com	Estudiante.


Los valores HASH_FICTICIO_NO_USAR no son hashes válidos para autenticar. Sirven para las pruebas SQL; para probar login se necesita una cuenta con un hash real generado por el backend.

La carga crea CALC-PRUEBA, las ediciones ED-PRUEBA-01 y ED-PRUEBA-02, SEC 1 y SEC 2 en cada edición, asignaciones docentes y una inscripción activa del estudiante en SEC 1 de la primera edición. Las fechas son estáticas y no demuestran vigencia académica actual.

Los módulos son Límites y Derivadas, con dos temas cada uno. Se consultan así:
SELECT c.nombre AS curso, m.nombre AS modulo, m.orden AS orden_modulo,
       t.nombre AS tema, t.orden AS orden_tema
FROM cursos c
JOIN modulos m ON m.curso_id = c.id
JOIN temas t ON t.modulo_id = m.id
WHERE c.codigo = 'CALC-PRUEBA'
ORDER BY m.orden, t.orden;
Se esperan Concepto de límite, Límites laterales, Concepto de derivada y Reglas de derivación. No depender de IDs concretos.
4.5 Seed de integración y cuenta con login real
Ejecutar database/seeds/datos_prueba_actividades_intentos.sql como postgres, después del esquema y seguridad. Requiere un administrador activo y el rol ESTUDIANTE del seed inicial; no depende de CALC-PRUEBA ni de IDs fijos. No utiliza 004 para crear su inscripción: es preparación administrativa de datos y no sustituye las pruebas de esa función.

Desde la carpeta backend, con las dependencias instaladas y bcryptjs presente en package.json:
node -e "console.log(require('bcryptjs').hashSync('DemoEquipo-2026!', 10))"
Desde la raíz del repositorio, en PowerShell (no dentro de psql):
chcp 65001
$env:PGCLIENTENCODING = 'UTF8'
psql -X -U postgres -d proyectofinal_db -f database/seeds/datos_prueba_actividades_intentos.sql
Pegar únicamente el hash de 60 caracteres cuando aparezca Hash bcrypt del estudiante demo:. La contraseña de postgres se solicita por separado. El seed debe contener \encoding UTF8 antes de BEGIN y guardarse en UTF-8. No pegar todo el archivo interactivamente: \prompt puede consumir una línea del script.
- Cuenta de aplicación: estudiante.demo@example.com; contraseña DemoEquipo-2026! si se generó el hash con el comando anterior. Es una credencial pública de demostración, no para producción ni para PostgreSQL.
- Crea un estudiante activo, curso DEMO-003, edición, sección, inscripción, módulo, tema y tres actividades. No crea una cuenta docente ni administradora con login.
- Cada actividad tiene una pregunta única y otra múltiple, de 10 puntos cada una. Usa las funciones de iniciar, guardar, entregar y calificar para los resultados.
- Práctica con promedio: dos intentos 0/20 y 20/20, promedio 50 y nota académica NULL. Evaluación: un intento 20/20, promedio y nota 100. Tercera práctica: sin intentos, lista para usar.
- Nuevos intentos están permitidos; modificarán los promedios. Disponibilidad termina un año después de crear los datos; duración de intento 30 minutos.
- Si ya existe la cuenta o el curso, se rechaza sin sobrescribir ni duplicar. No es un script de reinicio. Cada compañero debe ejecutarlo en su propia base; Git no transporta registros.
- Se observaron tildes dañadas por cargar UTF-8 como WIN1252. La base local fue reparada y los triggers restablecidos. No deshabilitar triggers ni repetir reparaciones como parte del flujo normal. Cambiar client_encoding no repara registros ya dañados.
4.6 Probar autenticación sin frontend
Configurar el backend para la misma base donde se cargó el seed y usar plataforma_backend. Obtener los nombres de variables de src/config/config.js, db.js y .env.example; no inventarlos. Mantener .env fuera de Git y definir JWT_SECRET local. Su generación puede hacerse con node -e "console.log(require('node:crypto').randomBytes(32).toString('hex'))".

En una terminal ejecutar npm start desde backend y conservarla abierta. En otra terminal PowerShell:
$puerto = 3000 # Sustituir por el puerto mostrado al iniciar el servidor.
$cuerpo = @{ email = 'estudiante.demo@example.com'; password = 'DemoEquipo-2026!' } | ConvertTo-Json
$respuesta = Invoke-RestMethod -Method Post -Uri "http://localhost:$puerto/api/auth/login" -ContentType 'application/json' -Body $cuerpo
Invoke-RestMethod -Method Get -Uri "http://localhost:$puerto/api/auth/me" -Headers @{ Authorization = "Bearer $($respuesta.token)" }
Se validaron ambas rutas y el rol ESTUDIANTE para el usuario demo. Esto no prueba por sí solo qué rol PostgreSQL usa la conexión del servidor; comprobar su configuración. No publicar el token. Las rutas académicas no se han verificado por HTTP. Los archivos de app revisados también exponen /api/docs y /api/docs.json; comprobar que su especificación coincide con la implementación actual.
5. Tablas y relaciones
Tabla	Responsabilidad
usuarios	Identidad, correo, hash y estado de cuenta.
roles	Catálogo de estudiante, docente y administrador.
usuario_roles	Asignaciones activas o desactivadas, con responsable y fechas.
cursos	Definición compartida de una materia.
curso_editores	Asignación de editores de materiales compartidos.
ediciones_curso	Oferta del curso en fechas determinadas.
secciones	Grupos y capacidad máxima dentro de una edición.
seccion_docentes	Asignación docente a una sección.
inscripciones	Participación del estudiante en una edición y sección.
modulos	Organización educativa del curso.
temas	Unidades temáticas dentro del módulo.
actividades	Práctica o evaluación de una sección y un tema.
preguntas	Enunciado, formato, orden y puntaje de cada pregunta.
opciones_respuestas	Alternativas y clave de corrección.
intentos	Cada inicio y entrega de una actividad por inscripción.
respuestas	Una respuesta por pregunta e intento, incluida la respuesta vacía.
respuesta_opciones	Opciones seleccionadas en cada respuesta.


Dos jerarquías comparten el curso: curso → edición → sección y curso → módulo → tema. La actividad enlaza una sección con un tema del mismo curso.

Las inscripciones usan la referencia compuesta sección–edición. Las respuestas usan referencias compuestas para exigir que intento y pregunta pertenezcan a la misma actividad, y que las opciones seleccionadas correspondan a esa pregunta.
6. Reglas de integridad
Identidad y organización académica
- Claves primarias enteras generadas mediante identidad, excepto la clave compuesta de respuesta_opciones.
- Textos esenciales obligatorios y no vacíos.
- Correo único sin distinguir mayúsculas mediante uq_usuarios_email sobre lower(email); sin espacios al principio o al final.
- Códigos únicos de rol y curso; código de edición único dentro del curso y de sección dentro de la edición.
- Una asignación por usuario–rol, curso–editor y sección–docente.
- Una inscripción por estudiante y edición, incluso si está cerrada; una eventual reactivación usa el mismo registro.
- Cupo máximo positivo; fechas de inscripción, edición y cierre coherentes.
- Orden entero positivo y único dentro del curso para módulos y del módulo para temas. Archivar no libera posiciones.
- No trasladar una edición a otro curso, una sección a otra edición, un módulo a otro curso ni un tema a otro módulo.
- Claves foráneas con ON DELETE RESTRICT para proteger registros referenciados. No prohíben por sí solas toda eliminación administrativa.
Inscripción mediante la migración 004
- Firma: inscribir_estudiante(seccion_id INTEGER, estudiante_id INTEGER, actor_id INTEGER); devuelve una fila de inscripciones.
- Cuenta del actor y del estudiante activas; estudiante con rol ESTUDIANTE activo.
- Si actor = estudiante: origen AUTONOMA. Si son distintos: actor con rol ADMINISTRADOR activo y origen ADMINISTRATIVA. Un administrador que se inscribe a sí mismo también necesita rol estudiante y usa origen AUTONOMA.
- Curso ACTIVO, edición ABIERTA y sección ABIERTA. Ventana de inscripción obligatoria: inicio incluido y cierre excluido.
- Los administradores respetan las mismas fechas y cupos. Solo las inscripciones ACTIVA cuentan para ocupar cupo.
- Rechaza una inscripción previa del estudiante en la edición en cualquier estado. No reactiva, traslada ni retira inscripciones.
- Bloquea la sección para coordinar ocupación; requiere READ COMMITTED. La prueba simultánea entre sesiones sigue pendiente.
- No se permite INSERT directo desde el backend por esta migración. Un administrador SQL puede eludir la función; futuras reactivaciones, traslados y cambios de cupo deben usar el mismo protocolo de coordinación.
- El actor debe proceder del token validado, no del cuerpo de la solicitud. La función recibe identidad; no valida JWT.
Actividades y publicación
- Una actividad pertenece a una sección y un tema del mismo curso.
- Finalidad PRACTICA o EVALUACION; método disponible: PROMEDIO.
- Límites de intentos y duración positivos; NULL significa sin límite correspondiente.
- Publicación con al menos una pregunta, dos opciones por pregunta, exactamente una correcta en selección única y al menos dos en múltiple.
- Preguntas y opciones se editan solamente en borrador y sin intentos. No se trasladan entre padres.
- Con intentos, la actividad no vuelve a borrador y conserva sección, tema, título, instrucciones, finalidad, política, límites, disponibilidad y datos de creación. Se permite archivarla.
Intentos y respuestas
- Un intento en curso por actividad e inscripción, protegido por índice único parcial.
- iniciar_intento() bloquea la actividad, comprueba propiedad, cuenta y rol estudiante activos, inscripción activa, sección, publicación, disponibilidad y límite.
- Numera el intento, copia la suma de puntajes y crea una respuesta vacía por pregunta.
- Vencimiento: el menor entre duración y cierre de disponibilidad; puede ser NULL si no hay ninguno.
- Guardado con reemplazo completo de selecciones; un arreglo vacío limpia la respuesta. Rechaza NULL, repetidos, opciones ajenas y más de una opción en selección única.
- Guardado solo en curso, sin calificación y antes del vencimiento. Entrega y guardado se coordinan mediante bloqueo del intento.
- La entrega comprueba propiedad y cuenta/rol activos. Un plazo vencido produce motivo VENCIMIENTO; de lo contrario, MANUAL.
- Repetir entrega o calificación devuelve el registro existente sin modificar sus fechas originales.
- Calificación de intentos entregados: conjunto seleccionado exactamente igual al correcto recibe puntaje completo; cualquier otra combinación, incluida una vacía, recibe cero.
- El intento obtiene la suma de sus respuestas. No se aceptan notas calculadas por el navegador.
Las funciones controlan las operaciones permitidas al rol del backend. Un superusuario sigue pudiendo modificar directamente datos; no debe utilizarse como conexión habitual de la aplicación.
7. Estados y funciones operativas
Entidad	Estados o valores
Curso	BORRADOR, ACTIVO, ARCHIVADO
Edición	PLANIFICADA, ABIERTA, EN_CURSO, FINALIZADA, CANCELADA
Sección	ABIERTA, CERRADA, CANCELADA
Inscripción	ACTIVA, RETIRADA, COMPLETADA, CANCELADA
Origen de inscripción	AUTONOMA, ADMINISTRATIVA
Módulo, tema y actividad	BORRADOR, PUBLICADO, ARCHIVADO
Intento	EN_CURSO, ENTREGADO, CALIFICADO
Motivo de entrega	MANUAL, VENCIMIENTO; vacío antes de entregar.


Función	Parámetros	Retorno
inscribir_estudiante	sección ID, estudiante ID, actor ID	Fila de inscripciones.
iniciar_intento	actividad ID, inscripción ID, estudiante ID	ID del intento.
guardar_opciones_respuesta	respuesta ID, estudiante ID, arreglo INTEGER[] de opciones	VOID.
entregar_intento	intento ID, estudiante ID	Fila de intentos.
calificar_intento	intento ID	Fila de intentos.


Ejemplos de consultas parametrizadas para el responsable del backend:
SELECT * FROM public.inscribir_estudiante($1, $2, $3);
SELECT public.iniciar_intento($1, $2, $3);
SELECT public.guardar_opciones_respuesta($1, $2, $3::INTEGER[]);
SELECT * FROM public.entregar_intento($1, $2);
SELECT * FROM public.calificar_intento($1);
Los marcadores $1 se utilizan con la biblioteca pg; no son comandos autónomos para pegar en psql. Las llamadas deben ir en transacciones breves. La calificación es una operación interna, no una ruta libre de asignación de notas al estudiante.
8. Vista de resultados
public.resultados_actividades calcula una fila por actividad e inscripción con al menos un intento. Devuelve contadores por estado, promedio_porcentaje y nota_academica_porcentaje.
- Solo los intentos CALIFICADO participan en el promedio.
- Cada resultado se convierte a porcentaje antes de promediar; se redondea el promedio final a dos decimales.
- Sin intentos calificados, el promedio es NULL, no cero.
- Una práctica muestra promedio, pero nota académica NULL.
- Una evaluación muestra el promedio como nota académica de esa actividad; no es la nota final del curso.
- Una actividad nunca iniciada no aparece: el dashboard necesitará una consulta que incluya también pendientes.
- Los resultados históricos no dependen de que la inscripción siga en la sección original.
La vista no filtra automáticamente por identidad autenticada. Express debe aplicar sus controles de acceso.
9. Roles PostgreSQL y credenciales
Rol	Uso y permisos
postgres	Administración y migraciones; mantiene la propiedad de tablas y vista.
plataforma_backend	Conexión de Express; lecturas autorizadas, registro actual y ejecución de las cinco funciones.
plataforma_operaciones	NOLOGIN, propietario de las cinco funciones, con permisos internos de lectura, bloqueo y escritura necesarios.


Las funciones operativas se configuran como SECURITY DEFINER, con propietario limitado, search_path=pg_catalog, public, pg_temp y ejecución retirada de PUBLIC. El backend no es miembro del rol interno.

El backend no tiene escritura directa en intentos, respuestas o selecciones, ni lectura directa de opciones_respuestas.es_correcta. Conserva lectura de usuarios —incluido el hash, necesario para autenticación— y otros registros: los servicios deben controlar qué campos se devuelven y a qué usuario. No se ha implementado RLS.

Para mantener el registro existente, conserva inserción limitada por columnas en usuarios y usuario_roles. Esto no garantiza por sí solo que una inserción SQL asigne únicamente estudiante; Express fija ese rol en el registro público. Encapsular el registro en una operación controlada sigue siendo una mejora pendiente.

No se concedieron permisos para administrar cursos o editar actividades desde Express; se añadirán con las operaciones correspondientes.
Configuración local de Express
Cuando el responsable integre el nuevo rol, establecer una contraseña local desde psql administrativo:
\password plataforma_backend
Configurar el .env local con DB_USER=plataforma_backend y su contraseña, conservando las demás variables del proyecto. No subir contraseñas, tokens, .env reales ni respaldos con información personal. .env.example solo debe contener valores ficticios.

Las pruebas con SET LOCAL ROLE no requieren contraseña y no demuestran todavía autenticación TCP de la cuenta ni integración con Express. La aplicación obtiene el estudiante de su sesión autenticada, nunca de un ID aceptado libremente del formulario.
10. Pruebas y evidencia
Resultados ya observados en PostgreSQL local
- Cinco rechazos iniciales: correo duplicado, sección duplicada, inscripción duplicada, sección de otra edición y retiro sin fecha de cierre.
- Cuatro rechazos de orden de módulos/temas y consulta correcta de su jerarquía.
- Curso incompatible en actividad y cambio de curso de un módulo rechazados.
- Edición de preguntas y opciones publicadas rechazada.
- Cuatro publicaciones inválidas rechazadas y publicación válida permitida.
- Actividad con intentos: retorno a borrador y cambio de límite rechazados; archivado permitido.
- Inicio válido; rechazos por inscripción ajena/inactiva, sección incorrecta, disponibilidad, intento abierto y límite agotado.
- Guardado, reemplazo y limpieza; rechazos de selección única múltiple, opciones ajenas, repetidas y respuesta de otro usuario.
- Entrega manual y por solicitud posterior al vencimiento; repetición conserva fecha; guardado posterior a entrega o plazo rechazado.
- Calificación de respuestas incorrectas, múltiples exactas/incompletas y vacías; intento abierto rechazado y repetición conserva resultado.
- Promedio entre intentos: abiertos y entregados sin calificar excluidos; práctica con 50 % sin nota académica y evaluación con 100 %.
- Escrituras directas bloqueadas al backend y recorrido completo permitido mediante funciones.
- Instalación desde archivos en proyectofinal_validacion: 17 tablas, 1 vista, 10 funciones y 9 triggers; seeds cargados y recorrido completo bajo plataforma_backend con 10/10, promedio 100 y nota académica NULL para la práctica.
Son comprobaciones realizadas progresivamente, no una certificación de todos los escenarios posibles.
Archivo consolidado de regresión
\connect proyectofinal_validacion
\i 'database/test/pruebas_migracion_003.sql'
Ejecutar como postgres, sin una transacción anterior abierta, después de instalar las migraciones, seguridad y ambos seeds. El archivo prepara sus propias actividades y utiliza los usuarios/curso de ejemplo existentes.

Incluye verificaciones del esquema funcional, permisos y recorrido completo. Captura los errores esperados en subtransacciones y comprueba su código y mensaje. También añade casos como cuenta/rol inactivos, elementos NULL y selección múltiple con opciones incorrectas adicionales.

En ejecución correcta imprime avisos OK y:
PRUEBAS 003 COMPLETADAS: todos los casos incluidos pasaron.
ROLLBACK
Estado del archivo consolidado: ejecución completa confirmada por el responsable de base de datos en PostgreSQL local; todos los casos incluidos finalizaron con el resultado esperado. Esta verificación no incluye concurrencia entre sesiones ni integración HTTP.

ON_ERROR_STOP detiene el archivo ante un fallo inesperado. En ese caso copiar el error y ejecutar ROLLBACK;. Los datos y funciones auxiliares se revierten al terminar; las secuencias pueden avanzar, por lo que no se exige numeración consecutiva sin huecos.

No incluye pruebas entre sesiones concurrentes, ejecución HTTP, navegador ni tarea programada de vencimientos.
Evidencia adicional de 004 y autenticación
Confirmado por ejecución local del responsable: creación de 004; backend sin INSERT sobre estudiante_id de inscripciones y con EXECUTE sobre la función; inscripción AUTONOMA válida; duplicado rechazado; actor estudiante rechazado al inscribir a otro; inscripción ADMINISTRATIVA válida; administrador rechazado al llenar el único cupo; conteo final de una ACTIVA para cupo uno. Los bloques son pruebas manuales transaccionales con ROLLBACK; verificar el cierre al terminar. Las pruebas consolidadas de database/test/pruebas_migracion_004.sql se ejecutaron satisfactoriamente en PostgreSQL local. Se verificaron permisos, inscripción autónoma y administrativa, duplicados, actor no autorizado y cupo lleno. Las pruebas de fechas, estados, cuentas/roles inactivos y concurrencia entre sesiones siguen pendientes.

El seed 003 mostró los resultados 50/100 previstos; login y GET /api/auth/me funcionaron. No extrapolar a inscripción HTTP, frontend, motor Python, autenticación TCP del rol limitado o concurrencia.

Pendientes específicos de 004: fechas y límites exactos, estados cerrados/inactivos, cuentas/roles inactivos, aislamiento distinto de READ COMMITTED y competencia entre sesiones por último cupo o por distintas secciones de la misma edición. La unicidad de estudiante/edición sigue siendo la última protección para solicitudes simultáneas en distintas secciones.
11. Pendientes y límites
Área	Pendiente
Cierre de esta entrega	Revisar rutas/archivos, diff final y preparar pull request.
Backend	Integrar las cinco funciones operativas, usar el rol limitado, mapear errores y verificar autorización por recurso. Login y /me ya probados; endpoints académicos pendientes.
Autenticación	Revisar múltiples roles (LIMIT 1 en el código recibido), búsqueda de correo sin rol activo y registro concurrente.
Concurrencia	Pruebas con dos sesiones de inicio, guardado, entrega y cambios administrativos.
Vencimientos	Proceso que entregue sin intervención del estudiante. La función actual solo detecta vencimiento cuando se solicita entregar.
Cuentas desactivadas	La entrega del estudiante exige cuenta/rol activos; el futuro cierre interno no debe depender de ellos.
Cupos	004 implementa bloqueo y conteo de ACTIVA. Falta prueba entre sesiones y operaciones controladas de reducción de cupo, traslado y reactivación.
Roles académicos	Resolver la política de incompatibilidad estudiante/docente y validar asignaciones/editores. No hay restricción implementada; no inferir que 004 la aplica.
Cambios de sección	Historial y operación controlada que conserve intentos previos.
Acceso académico	Reglas de fechas de edición, estado de sección y publicación de módulo/tema; iniciar intento actualmente valida actividad e inscripción, no todas esas condiciones.
Materiales	Tabla de contenidos y mecanismos de acceso/publicación.
Progreso	Próxima propuesta: vista por inscripción y tema. Definir actividades obligatorias y finalización antes del SQL; no existe aún esa vista ni tabla.
Motor adaptativo	Adaptador de intentos/respuestas/resultados y semántica de métricas. No se requiere crear interacciones por defecto; recomendaciones persistentes solo si se acuerdan.
Auditoría	Actualización general de actualizado_en; las funciones solo actualizan los campos que les corresponden.
Evolución de contenido	No editar actividades usadas; una revisión importante se crea como otra actividad. No hay sistema formal de versiones.


No se incorporó el rol worker ni el procesamiento por lotes propuesto para cierre automático: se pospuso para mantener esta entrega acotada. La ventana de cinco registros y las métricas opcionales del motor son propuestas pendientes de coordinación, no reglas implementadas.
12. Gestión de cambios y entrega al equipo
No existe todavía un ejecutor de migraciones ni una tabla de control de versiones aplicadas. Registrar qué archivos se ejecutaron en cada entorno.
- Una base con 001 y 002 aplica 003 → seguridad → 004. Una base con 001–003 y seguridad ya instalados aplica solo 004. No ejecutar otra vez los CREATE TABLE anteriores.
- Una base donde 003 se construyó bloque a bloque no debe volver a ejecutar el archivo completo: conciliarla mediante cambios incrementales o utilizar una nueva base de validación.
- No reescribir migraciones ya adoptadas por el equipo para cambiar bases existentes; crear nuevas migraciones.
- La 003 corregida es el archivo que se validó desde cero. La corrección del cierre END; no obliga a recrear funciones que ya funcionan en la base local.
- Si se reemplazan las funciones operativas, conservar SECURITY DEFINER y el search_path correspondiente o reaplicar su configuración de seguridad. No asumir que un reemplazo conserva todas sus propiedades.
- Subir migración, seguridad, pruebas y este README en una rama y solicitar revisión mediante pull request.
- El merge no ejecuta SQL. Cada integrante aplica los cambios en su entorno y configura sus credenciales por separado.
La validación local del esquema no implica que las pantallas o la API ya utilicen este bloque. Coordinar su integración con el responsable de Express y mantener los pendientes explícitos en la entrega.