-- 1. Correo duplicado cambiando mayúsculas
BEGIN;

INSERT INTO usuarios (nombre, apellido, email, password_hash)
VALUES (
    'Duplicado',
    'Prueba',
    'ESTUDIANTE@example.com',
    'HASH_FICTICIO_NO_USAR'
);

ROLLBACK;

-- 2. Repetir SEC 1 dentro de la misma edición
BEGIN;

INSERT INTO secciones (
    edicion_id, codigo, cupo_maximo, creado_por
)
SELECT
    e.id,
    'SEC 1',
    25,
    u.id
FROM ediciones_curso e
JOIN cursos c ON c.id = e.curso_id
CROSS JOIN usuarios u
WHERE c.codigo = 'CALC-PRUEBA'
  AND e.codigo = 'ED-PRUEBA-01'
  AND u.email = 'admin@example.com';

ROLLBACK;

-- 3. Inscribir dos veces al estudiante en la misma edición
BEGIN;

INSERT INTO inscripciones (
    estudiante_id, edicion_id, seccion_id,
    origen, registrado_por
)
SELECT
    u.id,
    e.id,
    s.id,
    'AUTONOMA',
    u.id
FROM usuarios u
JOIN cursos c ON c.codigo = 'CALC-PRUEBA'
JOIN ediciones_curso e ON e.curso_id = c.id
JOIN secciones s ON s.edicion_id = e.id
WHERE u.email = 'estudiante@example.com'
  AND e.codigo = 'ED-PRUEBA-01'
  AND s.codigo = 'SEC 2';

ROLLBACK;

-- 4. Cambiar la inscripción a una sección de otra edición
BEGIN;

UPDATE inscripciones
SET seccion_id = (
    SELECT s.id
    FROM secciones s
    JOIN ediciones_curso e ON e.id = s.edicion_id
    JOIN cursos c ON c.id = e.curso_id
    WHERE c.codigo = 'CALC-PRUEBA'
      AND e.codigo = 'ED-PRUEBA-02'
      AND s.codigo = 'SEC 1'
)
WHERE estudiante_id = (
    SELECT id
    FROM usuarios
    WHERE email = 'estudiante@example.com'
)
AND edicion_id = (
    SELECT e.id
    FROM ediciones_curso e
    JOIN cursos c ON c.id = e.curso_id
    WHERE c.codigo = 'CALC-PRUEBA'
      AND e.codigo = 'ED-PRUEBA-01'
);

ROLLBACK;

-- 5. Retirar al estudiante sin registrar fecha de cierre
BEGIN;

UPDATE inscripciones
SET estado = 'RETIRADA',
    cerrado_en = NULL
WHERE estudiante_id = (
    SELECT id
    FROM usuarios
    WHERE email = 'estudiante@example.com'
);

ROLLBACK;