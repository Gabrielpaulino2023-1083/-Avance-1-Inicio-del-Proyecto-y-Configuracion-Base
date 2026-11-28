# Base de datos — plataforma educativa

Entrega consolidada **010/011 para revisión**, posterior a la base main a8accad8f494c5050564e9dbd97535479e98d407. Los archivos de esta entrega se prepararon localmente; no se publicaron ni se ejecutaron sobre el servidor del equipo.

**Estado comprobado:** 010 y 011 tienen pruebas funcionales y concurrentes locales aprobadas, confirmadas por Jeison. Las operaciones SQL están disponibles tras instalarlas; los endpoints y pantallas de gestión editorial y de INC-09 necesitan integración del backend/frontend. El cierre del registro directo está preparado, pero no se aplica todavía.

## Documentos vigentes

| Documento | Contenido |
|---|---|
| [Contrato de integración](docs/CONTRATO_INTEGRACION_BD.md) | Permisos, operaciones, seguridad y responsabilidades |
| [Diccionario](docs/DICCIONARIO_DATOS_BD.md) | Tipos y restricciones; incluido el retorno seguro de 011 |
| [Cuestionarios 010](docs/GESTION_CUESTIONARIOS_010.md) | Gestión editorial, publicación, copia, estados y claves |
| [Firmas 010](docs/FIRMAS_010.md) | Parámetros y retornos exactos |
| [Usuarios 011](docs/USUARIOS_ROLES_011.md) | INC-09, roles, transiciones y registro en dos fases |
| [Firmas 011](docs/FIRMAS_USUARIOS_011.md) | Parámetros y retornos exactos |
| [Entrega 010/011](docs/ENTREGA_010_011.md) | Qué se validó y qué falta integrar |

Las guías de 005–009 ya presentes en el repositorio siguen siendo referencias operativas para sus funciones. El contrato histórico 009 se conserva separado y no es la fuente del estado actual.

## Estructura y migraciones

Después de instalar 001–011 y seguridad: **17 tablas, 94 funciones propias, 15 triggers, una vista de resultados y un tipo compuesto de retorno creado en 011**. No se cuentan extensiones, tipos fila automáticos ni auxiliares temporales de pruebas.

| Migración | Responsabilidad |
|---|---|
| 001 | Usuarios, roles, cursos, ediciones, secciones, asignaciones e inscripciones |
| 002 | Módulos y temas |
| 003 | Actividades, cuestionarios, intentos, respuestas, entrega y calificación |
| Seguridad 001 | Roles PostgreSQL y privilegios iniciales |
| 004 | Inscripción autónoma/administrativa y cupos |
| 005 | Administración de cursos |
| 006 | Gestión de módulos y temas |
| 007 | Lecturas del estudiante sin claves |
| 008 | Selector, resultados, progreso, minutos e interacciones del motor |
| 009 | Dificultad y candidatas autorizadas |
| 010 | Gestión docente de actividades, preguntas y opciones |
| 011 | Gestión de usuarios/roles, registro controlado y protecciones de identidad |

No reescribir migraciones publicadas. La secuencia nueva es **001 → 002 → 003 → seguridad → 004 → … → 011**. Las migraciones se aplican una vez por base. No existe un ejecutor automático de versiones ni un script que adivine el historial aplicado; registrarlo por entorno. El merge no ejecuta SQL.

## Instalación

Requiere PostgreSQL, psql, Node para concurrencia y pg instalado como dependencia del backend. Instalar como cuenta administradora; Express usa plataforma_backend.

### Base nueva

El instalador encadena 001–011 en orden y rechaza una base con tablas públicas. No carga seeds ni cierra el registro antiguo.

```powershell
$baseNueva = 'proyectofinal_revision011_' + (Get-Date -Format 'yyyyMMdd_HHmmss')
createdb -U postgres $baseNueva
if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear la base.' }
psql -X -U postgres -d $baseNueva -v ON_ERROR_STOP=1 -f database/test/instalar_revision_011.sql
if ($LASTEXITCODE -ne 0) { throw 'La instalacion fallo; revisar antes de seguir.' }
```

### Base existente

Respaldar antes de actualizar y aplicar solo lo pendiente. Si ya se validaron 010 y 011, no reinstalarlas. Consultar los objetos de la base de destino y seguir LEEME_010.md / LEEME_011.md para las dependencias; comprobar firmas no sustituye pasar las pruebas.

```sql
SELECT current_database(), current_user, version();
SELECT to_regprocedure('public.publicar_actividad(integer,integer)') AS funcion_010,
       to_regtype('public.usuario_resumen_011') AS tipo_011,
       to_regprocedure('public.registrar_estudiante(text,text,text,text)') AS registro_011;
```

Usar siempre -h/-p/-d explícitos si hay varios servidores. psql y Node deben apuntar al mismo destino. Un error de tipo o función ausente en otra base no se corrige repitiendo una migración ya instalada en la primera.

## Pruebas

Pruebas funcionales propias de 010/011: fixtures SQL y ROLLBACK; no requieren seeds. Las secuencias pueden avanzar. Usar postgres sin transacción abierta; las pruebas cambian internamente a plataforma_backend.

```powershell
psql -X -U postgres -d TU_BASE -v ON_ERROR_STOP=1 -f database/test/pruebas_migracion_010.sql
# Continuar solo si termino correctamente:
psql -X -U postgres -d TU_BASE -v ON_ERROR_STOP=1 -f database/test/pruebas_migracion_011.sql
```

Concurrencia: usar únicamente el lanzador corregido. Crea bases separadas, instala 010/011 según el caso y configura las variables. No depende de $baseNueva ni reutiliza desarrollo.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\database\test\ejecutar_concurrencia_010_011.ps1
```

La política de ejecución se aplica solo a ese proceso. Se piden credenciales con Get-Credential y se restauran las variables del entorno al finalizar. La prueba 010 limpia sus fixtures; la 011 los conserva en su base descartable para respetar al último administrador. No desactivar triggers para limpiarla.

Regresiones 003–009: conservar sus fixtures/seeds y seguir las instrucciones de cada archivo. Las pruebas funcionales, concurrentes y la integración HTTP son evidencias distintas. Logs del asistente: test/concurrencia_postgresql_18_6.log, test/validacion_postgresql_18_6.log y test/correccion_prevalidacion_linux.log. La validación Windows está registrada como confirmación de Jeison; guardar los logs finales de su equipo por separado.

## Datos de demostración

| Seed | Dependencia / propósito |
|---|---|
| datos_prueba.sql | Catálogos y escenario inicial; hashes ficticios de algunas cuentas no sirven para login |
| datos_prueba_modulos_temas.sql | Módulos/temas del escenario inicial |
| datos_prueba_actividades_intentos.sql | Estudiante autenticable, actividades e intentos; requiere hash bcrypt |
| datos_prueba_administrador.sql | Administrador demo autenticable |
| datos_prueba_docente.sql | Docente demo y curso DEMO-006 |
| datos_prueba_integracion_resultados.sql | Tres temas SQL y resultados históricos |
| datos_prueba_dificultad_009.sql | Referencia y actividades BAJA/MEDIA/ALTA; reutiliza estudiante |
| datos_prueba_gestion_cuestionarios_010.sql | Curso separado, doble asignación docente y prácticas creadas por funciones |

No cargar todos automáticamente al iniciar Express. Seguir dependencias y prompts de cada seed; ejecutar como administrador. Los seeds reejecutables conservan contenido e intentos y no son herramientas de reinicio. No asumir IDs fijos. Elegir y verificar el escenario oficial antes de centralizar.

Las cuentas demo siguen siendo las existentes; 010/011 no cambian sus contraseñas. Generar hashes con bcryptjs siguiendo las guías anteriores; no publicar .env, tokens, passwords PostgreSQL o hashes reales de usuarios.

## Seguridad y transición de registro

- Roles de aplicación: ESTUDIANTE, DOCENTE, ADMINISTRADOR; distintos de los roles PostgreSQL.
- Express: plataforma_backend; propietario operativo de funciones: plataforma_operaciones NOLOGIN. No usar postgres como cuenta habitual de Express.
- Las funciones editoriales 010 exigen editor del curso y docente de la sección; un rol docente aislado no basta.
- 011 bloquea ESTUDIANTE+DOCENTE activos y protege al último administrador efectivo, también frente a SQL directo. ADMINISTRADOR puede coexistir con uno académico.
- No se amplían escrituras directas sobre cuestionarios. La lectura editorial de claves requiere autorización; 007 no las devuelve.
- 011 mantiene temporalmente INSERT de registro para compatibilidad. security/002_cerrar_registro_directo.sql solo se aplica cuando backend ya usa registrar_estudiante y registro/login se comprobaron. No forma parte del instalador.
- Tras el cierre, no reaplicar security/001_roles_permisos.sql como si fuera un script idempotente de permisos: volvería a habilitar los INSERT antiguos.
- No hay RLS: el rol compartido y las funciones no sustituyen la autenticación del backend. Revalidar cuenta/roles actuales, no confiar solo en un JWT anterior a una revocación.

## Lo que sigue pendiente

Integración HTTP de 010/INC-09 y sus evidencias; cierre de registro cuando corresponda; operaciones de ediciones/secciones/asignaciones e inscripciones; consistencia/cierre de intentos y métricas; base central por red privada; datos oficiales; respaldo y restauración comprobados en otra computadora. Los pendientes se enumeran en esta sección. No se declara completada toda la BD v1 ni desplegada la base central.
