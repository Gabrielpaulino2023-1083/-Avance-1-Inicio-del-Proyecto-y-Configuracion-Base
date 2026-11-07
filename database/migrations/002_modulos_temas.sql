BEGIN;

CREATE TABLE modulos (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    curso_id INTEGER NOT NULL REFERENCES cursos(id) ON DELETE RESTRICT,
    nombre TEXT NOT NULL CHECK (btrim(nombre) <> ''),
    descripcion TEXT NOT NULL CHECK (btrim(descripcion) <> ''),
    orden INTEGER NOT NULL CHECK (orden > 0),
    estado VARCHAR(50) NOT NULL DEFAULT 'BORRADOR' CHECK ( estado IN ('BORRADOR', 'PUBLICADO', 'ARCHIVADO')),  
    creado_por INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uq_modulos_curso_orden
        UNIQUE (curso_id, orden),

    CONSTRAINT ck_modulos_fechas
        CHECK (actualizado_en >= creado_en)
);
    
    
CREATE TABLE temas (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    modulo_id INTEGER NOT NULL REFERENCES modulos(id) ON DELETE RESTRICT,
    nombre TEXT NOT NULL CHECK (btrim(nombre) <> ''),
    descripcion TEXT NOT NULL CHECK (btrim(descripcion) <> ''),
    orden INTEGER NOT NULL CHECK (orden > 0),
    estado VARCHAR(50) NOT NULL DEFAULT 'BORRADOR' CHECK ( estado IN ('BORRADOR', 'PUBLICADO', 'ARCHIVADO')),
    creado_por INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uq_temas_modulo_orden
        UNIQUE (modulo_id, orden),
    
    CONSTRAINT ck_temas_fechas
        CHECK (actualizado_en >= creado_en)
);

COMMIT;  
