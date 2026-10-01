BEGIN;

CREATE TABLE usuarios (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL CHECK (btrim(nombre) <> ''),
    apellido VARCHAR(50) NOT NULL CHECK (btrim(apellido) <> ''),
    email TEXT NOT NULL CHECK (btrim(email) <> '' AND email = btrim(email)),
    password_hash TEXT NOT NULL CHECK (btrim(password_hash) <> ''),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (actualizado_en >= creado_en)
);

-- Evita registrar el mismo correo con diferentes mayúsculas.
CREATE UNIQUE INDEX uq_usuarios_email
    ON usuarios (lower(email));

CREATE TABLE roles (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE CHECK (codigo IN ('ESTUDIANTE', 'DOCENTE', 'ADMINISTRADOR')),
    nombre VARCHAR(50) NOT NULL CHECK (btrim(nombre) <> '')
);

CREATE TABLE usuario_roles (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    rol_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    asignado_por INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    asignado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    desactivado_en TIMESTAMPTZ,
    UNIQUE(usuario_id, rol_id),
    CONSTRAINT ck_usuario_roles_desactivacion CHECK (
        (activo = TRUE AND desactivado_en IS NULL)
        OR
        (
            activo = FALSE
            AND desactivado_en IS NOT NULL
            AND desactivado_en >= asignado_en
        )
    )
);

CREATE TABLE cursos (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo TEXT NOT NULL UNIQUE CHECK (btrim(codigo) <> ''),
    nombre TEXT NOT NULL CHECK (btrim(nombre) <> ''),
    descripcion TEXT NOT NULL CHECK (btrim(descripcion) <> ''),
    estado VARCHAR(50) NOT NULL DEFAULT 'BORRADOR' CHECK (estado IN ('BORRADOR', 'ACTIVO', 'ARCHIVADO')),
    creado_por INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CHECK (actualizado_en >= creado_en)
);

CREATE TABLE curso_editores(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    curso_id INTEGER NOT NULL REFERENCES cursos(id) ON DELETE RESTRICT,
    usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    asignado_por INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    asignado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(curso_id, usuario_id)
);

CREATE TABLE ediciones_curso(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    curso_id INTEGER NOT NULL REFERENCES cursos(id) ON DELETE RESTRICT,
    codigo TEXT NOT NULL CHECK (btrim(codigo) <> ''),
    nombre TEXT NOT NULL CHECK (btrim(nombre) <> ''),
    fecha_inicio TIMESTAMPTZ NOT NULL,
    fecha_fin TIMESTAMPTZ NOT NULL,
    inscripcion_desde TIMESTAMPTZ,
    inscripcion_hasta TIMESTAMPTZ,
    estado VARCHAR(50) NOT NULL DEFAULT 'PLANIFICADA' CHECK (estado IN ('PLANIFICADA', 'ABIERTA', 'EN_CURSO', 'FINALIZADA', 'CANCELADA')),
    creado_por INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (curso_id, codigo),

    CHECK (fecha_fin >= fecha_inicio),

    CONSTRAINT ck_ediciones_ventana_inscripcion CHECK (
        (
            inscripcion_desde IS NULL
            AND inscripcion_hasta IS NULL
        )
        OR
        (
            inscripcion_desde IS NOT NULL
            AND inscripcion_hasta IS NOT NULL
            AND inscripcion_hasta >= inscripcion_desde
            AND inscripcion_hasta <= fecha_fin
        )
    ),

    CONSTRAINT ck_ediciones_fechas_obligatorias CHECK (
        estado IN ('PLANIFICADA', 'CANCELADA')
        OR
        (
            inscripcion_desde IS NOT NULL
            AND inscripcion_hasta IS NOT NULL
        )
    )
);

CREATE TABLE secciones (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    edicion_id INTEGER NOT NULL REFERENCES ediciones_curso(id) ON DELETE RESTRICT, 
    codigo TEXT NOT NULL CHECK (btrim(codigo) <> ''),
    cupo_maximo INTEGER NOT NULL CHECK (cupo_maximo > 0),
    estado VARCHAR(50) NOT NULL DEFAULT 'CERRADA' CHECK (estado IN ('ABIERTA', 'CERRADA', 'CANCELADA')),
    creado_por INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (edicion_id, codigo),
    UNIQUE (id, edicion_id)
);

CREATE TABLE seccion_docentes(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    seccion_id INTEGER NOT NULL REFERENCES secciones(id) ON DELETE RESTRICT,
    usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    asignado_por INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    asignado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(seccion_id, usuario_id)
);

CREATE TABLE inscripciones(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    estudiante_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    edicion_id INTEGER NOT NULL REFERENCES ediciones_curso(id) ON DELETE RESTRICT,
    seccion_id INTEGER NOT NULL,
    estado VARCHAR(50) NOT NULL DEFAULT 'ACTIVA' CHECK (estado IN ('ACTIVA', 'RETIRADA', 'COMPLETADA', 'CANCELADA')),
    origen VARCHAR(50) NOT NULL CHECK (origen IN ('AUTONOMA', 'ADMINISTRATIVA')),
    registrado_por INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    inscrito_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cerrado_en TIMESTAMPTZ, 
    UNIQUE (estudiante_id, edicion_id),

    CONSTRAINT fk_inscripciones_seccion_edicion
        FOREIGN KEY (seccion_id, edicion_id)
        REFERENCES secciones(id, edicion_id)
        ON DELETE RESTRICT,

    CONSTRAINT ck_inscripciones_cierre CHECK (
        (estado = 'ACTIVA' AND cerrado_en IS NULL)
        OR
        (
            estado <> 'ACTIVA'
            AND cerrado_en IS NOT NULL
            AND cerrado_en >= inscrito_en
        )
    ),

    CONSTRAINT ck_inscripciones_origen CHECK (
        origen <> 'AUTONOMA'
        OR registrado_por = estudiante_id
    )
);

COMMIT;
