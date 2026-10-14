--Creacion de dos modulos y dos temas para cada modulo del curso de prueba CALC-PRUEBA

BEGIN;

INSERT INTO modulos (
    curso_id, nombre, descripcion, orden, estado, creado_por
)
SELECT
    c.id,
    datos.nombre,
    datos.descripcion,
    datos.orden,
    'PUBLICADO',
    u.id
FROM cursos c
CROSS JOIN usuarios u
CROSS JOIN (
    VALUES
        ('Límites', 'Introducción al estudio de límites.', 1),
        ('Derivadas', 'Introducción al cálculo de derivadas.', 2)
) AS datos(nombre, descripcion, orden)
WHERE c.codigo = 'CALC-PRUEBA'
  AND u.email = 'admin@example.com';


INSERT INTO temas (
    modulo_id, nombre, descripcion, orden, estado, creado_por
)
SELECT
    m.id,
    datos.nombre,
    datos.descripcion,
    datos.orden,
    'PUBLICADO',
    u.id
FROM modulos m
JOIN cursos c ON c.id = m.curso_id
CROSS JOIN usuarios u
JOIN (
    VALUES
        (1, 'Concepto de límite', 'Definición e interpretación de límites.', 1),
        (1, 'Límites laterales', 'Límites por la izquierda y por la derecha.', 2),
        (2, 'Concepto de derivada', 'Interpretación de la tasa de cambio.', 1),
        (2, 'Reglas de derivación', 'Reglas básicas para calcular derivadas.', 2)
) AS datos(orden_modulo, nombre, descripcion, orden)
    ON datos.orden_modulo = m.orden
WHERE c.codigo = 'CALC-PRUEBA'
  AND u.email = 'admin@example.com';

COMMIT;


