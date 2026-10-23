-- 1. Repetir el orden de un modulo dentro del mismo curso

BEGIN;

INSERT INTO modulos (
    curso_id, nombre, descripcion, orden, creado_por
)
SELECT
    c.id, 'Módulo duplicado', 'Prueba de unicidad.', 1, u.id
FROM cursos c
CROSS JOIN usuarios u
WHERE c.codigo = 'CALC-PRUEBA'
  AND u.email = 'admin@example.com';

ROLLBACK;

-- 2. Repetir el orden de un tema dentro del mismo modulo

BEGIN;

INSERT INTO temas (
    modulo_id, nombre, descripcion, orden, creado_por
)
SELECT
    m.id, 'Tema duplicado', 'Prueba de unicidad.', 1, u.id
FROM modulos m
JOIN cursos c ON c.id = m.curso_id
CROSS JOIN usuarios u
WHERE c.codigo = 'CALC-PRUEBA'
  AND m.orden = 1
  AND u.email = 'admin@example.com';

ROLLBACK;

-- 3. Asignar posicion cero a un modulo inexistente

BEGIN;

UPDATE modulos
SET orden = 0
WHERE curso_id = (
    SELECT id FROM cursos WHERE codigo = 'CALC-PRUEBA'
)
AND orden = 1;

ROLLBACK;

-- 4. Asignar posicion negativa a un tema

BEGIN;

UPDATE temas
SET orden = -1
WHERE modulo_id = (
    SELECT m.id
    FROM modulos m
    JOIN cursos c ON c.id = m.curso_id
    WHERE c.codigo = 'CALC-PRUEBA'
      AND m.orden = 1
)
AND orden = 1;

ROLLBACK;