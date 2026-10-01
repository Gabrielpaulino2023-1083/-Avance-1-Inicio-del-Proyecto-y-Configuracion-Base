BEGIN;

-- 1. Roles
INSERT INTO roles (codigo, nombre)
VALUES
    ('ADMINISTRADOR', 'Administrador'),
    ('DOCENTE', 'Docente'),
    ('ESTUDIANTE', 'Estudiante')
ON CONFLICT (codigo) DO NOTHING;


-- 2. Usuarios ficticios
INSERT INTO usuarios (
    nombre, apellido, email, password_hash
)
VALUES
    ('Ana', 'Prueba', 'admin@example.com', 'HASH_FICTICIO_NO_USAR'),
    ('Carlos', 'Prueba', 'docente@example.com', 'HASH_FICTICIO_NO_USAR'),
    ('Jeison', 'Prueba', 'estudiante@example.com', 'HASH_FICTICIO_NO_USAR');


-- 3. Asignar un rol a cada usuario
-- El administrador inicial registra su propia asignación.
INSERT INTO usuario_roles (
    usuario_id, rol_id, asignado_por
)
SELECT
    u.id,
    r.id,
    administrador.id
FROM (
    VALUES
        ('admin@example.com', 'ADMINISTRADOR'),
        ('docente@example.com', 'DOCENTE'),
        ('estudiante@example.com', 'ESTUDIANTE')
) AS datos(email, codigo_rol)
JOIN usuarios u ON u.email = datos.email
JOIN roles r ON r.codigo = datos.codigo_rol
CROSS JOIN usuarios administrador
WHERE administrador.email = 'admin@example.com';


-- 4. Curso
INSERT INTO cursos (
    codigo, nombre, descripcion, estado, creado_por
)
SELECT
    'CALC-PRUEBA',
    'Cálculo',
    'Curso ficticio para verificar la estructura académica.',
    'ACTIVO',
    id
FROM usuarios
WHERE email = 'admin@example.com';


-- 5. Autorizar al docente para editar el curso
INSERT INTO curso_editores (
    curso_id, usuario_id, asignado_por
)
SELECT
    c.id,
    docente.id,
    administrador.id
FROM cursos c
CROSS JOIN usuarios docente
CROSS JOIN usuarios administrador
WHERE c.codigo = 'CALC-PRUEBA'
  AND docente.email = 'docente@example.com'
  AND administrador.email = 'admin@example.com';


-- 6. Dos ediciones del mismo curso
INSERT INTO ediciones_curso (
    curso_id,
    codigo,
    nombre,
    fecha_inicio,
    fecha_fin,
    inscripcion_desde,
    inscripcion_hasta,
    estado,
    creado_por
)
SELECT
    c.id,
    datos.codigo,
    datos.nombre,
    datos.fecha_inicio,
    datos.fecha_fin,
    datos.inscripcion_desde,
    datos.inscripcion_hasta,
    'ABIERTA',
    administrador.id
FROM cursos c
CROSS JOIN usuarios administrador
CROSS JOIN (
    VALUES
        (
            'ED-PRUEBA-01',
            'Primera edición de prueba',
            TIMESTAMPTZ '2026-11-01 08:00:00-04',
            TIMESTAMPTZ '2027-01-31 18:00:00-04',
            TIMESTAMPTZ '2026-10-01 00:00:00-04',
            TIMESTAMPTZ '2026-10-31 23:59:00-04'
        ),
        (
            'ED-PRUEBA-02',
            'Segunda edición de prueba',
            TIMESTAMPTZ '2027-02-01 08:00:00-04',
            TIMESTAMPTZ '2027-04-30 18:00:00-04',
            TIMESTAMPTZ '2027-01-01 00:00:00-04',
            TIMESTAMPTZ '2027-01-31 23:59:00-04'
        )
) AS datos(
    codigo, nombre, fecha_inicio, fecha_fin,
    inscripcion_desde, inscripcion_hasta
)
WHERE c.codigo = 'CALC-PRUEBA'
  AND administrador.email = 'admin@example.com';


-- 7. Dos secciones por edición
-- SEC 1 y SEC 2 pueden repetirse entre ediciones.
INSERT INTO secciones (
    edicion_id, codigo, cupo_maximo, estado, creado_por
)
SELECT
    e.id,
    datos.codigo,
    25,
    'ABIERTA',
    administrador.id
FROM ediciones_curso e
JOIN cursos c ON c.id = e.curso_id
CROSS JOIN usuarios administrador
CROSS JOIN (
    VALUES ('SEC 1'), ('SEC 2')
) AS datos(codigo)
WHERE c.codigo = 'CALC-PRUEBA'
  AND e.codigo IN ('ED-PRUEBA-01', 'ED-PRUEBA-02')
  AND administrador.email = 'admin@example.com';


-- 8. Asignar el mismo docente a las cuatro secciones
INSERT INTO seccion_docentes (
    seccion_id, usuario_id, asignado_por
)
SELECT
    s.id,
    docente.id,
    administrador.id
FROM secciones s
JOIN ediciones_curso e ON e.id = s.edicion_id
JOIN cursos c ON c.id = e.curso_id
CROSS JOIN usuarios docente
CROSS JOIN usuarios administrador
WHERE c.codigo = 'CALC-PRUEBA'
  AND e.codigo IN ('ED-PRUEBA-01', 'ED-PRUEBA-02')
  AND docente.email = 'docente@example.com'
  AND administrador.email = 'admin@example.com';


-- 9. Inscripción autónoma en SEC 1 de la primera edición
INSERT INTO inscripciones (
    estudiante_id,
    edicion_id,
    seccion_id,
    origen,
    registrado_por
)
SELECT
    estudiante.id,
    e.id,
    s.id,
    'AUTONOMA',
    estudiante.id
FROM usuarios estudiante
JOIN cursos c ON c.codigo = 'CALC-PRUEBA'
JOIN ediciones_curso e ON e.curso_id = c.id
JOIN secciones s ON s.edicion_id = e.id
WHERE estudiante.email = 'estudiante@example.com'
  AND e.codigo = 'ED-PRUEBA-01'
  AND s.codigo = 'SEC 1';

COMMIT;