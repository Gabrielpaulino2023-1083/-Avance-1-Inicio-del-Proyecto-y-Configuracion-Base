# Firmas y retornos — usuarios y roles 011

Las firmas son SQL, no rutas HTTP. Ver USUARIOS_ROLES_011.md para permisos, nulabilidad y transición de registro.

## registrar_estudiante

```sql
public.registrar_estudiante(
    p_nombre TEXT,
    p_apellido TEXT,
    p_email TEXT,
    p_hash TEXT
) RETURNS public.usuario_resumen_011
```

## crear_usuario_admin

```sql
public.crear_usuario_admin(
    p_actor INTEGER,
    p_nombre TEXT,
    p_apellido TEXT,
    p_email TEXT,
    p_hash TEXT,
    p_rol TEXT
) RETURNS public.usuario_resumen_011
```

## listar_usuarios_admin

```sql
public.listar_usuarios_admin(
    p_actor INTEGER,
    p_activo BOOLEAN DEFAULT NULL,
    p_rol TEXT DEFAULT NULL,
    p_busqueda TEXT DEFAULT NULL,
    p_limite INTEGER DEFAULT 50,
    p_desplazamiento INTEGER DEFAULT 0
) RETURNS SETOF public.usuario_resumen_011
```

## obtener_usuario

```sql
public.obtener_usuario(
    p_actor INTEGER,
    p_usuario INTEGER
) RETURNS public.usuario_resumen_011
```

## actualizar_usuario_admin

```sql
public.actualizar_usuario_admin(
    p_actor INTEGER,
    p_usuario INTEGER,
    p_nombre TEXT,
    p_apellido TEXT,
    p_email TEXT
) RETURNS public.usuario_resumen_011
```

## actualizar_mi_perfil

```sql
public.actualizar_mi_perfil(
    p_actor INTEGER,
    p_nombre TEXT,
    p_apellido TEXT
) RETURNS public.usuario_resumen_011
```

## cambiar_estado_usuario_admin

```sql
public.cambiar_estado_usuario_admin(
    p_actor INTEGER,
    p_usuario INTEGER,
    p_activo BOOLEAN
) RETURNS public.usuario_resumen_011
```

## asignar_rol_usuario

```sql
public.asignar_rol_usuario(
    p_actor INTEGER,
    p_usuario INTEGER,
    p_rol TEXT
) RETURNS public.usuario_resumen_011
```

## desactivar_rol_usuario

```sql
public.desactivar_rol_usuario(
    p_actor INTEGER,
    p_usuario INTEGER,
    p_rol TEXT
) RETURNS public.usuario_resumen_011
```

## cambiar_rol_academico

```sql
public.cambiar_rol_academico(
    p_actor INTEGER,
    p_usuario INTEGER,
    p_rol TEXT
) RETURNS public.usuario_resumen_011
```

## actualizar_hash_usuario

```sql
public.actualizar_hash_usuario(
    p_actor INTEGER,
    p_usuario INTEGER,
    p_hash TEXT
) RETURNS public.usuario_resumen_011
```

## Auxiliares privados

- `g011_serializar() RETURNS VOID`
- `g011_serializar_sentencia() RETURNS TRIGGER`
- `g011_admin(p_actor INTEGER) RETURNS VOID`
- `g011_objetivo(p_actor INTEGER, p_usuario INTEGER, p_solo_admin BOOLEAN) RETURNS VOID`
- `g011_resumen(p_usuario INTEGER) RETURNS public.usuario_resumen_011`
- `g011_datos(p_nombre TEXT, p_apellido TEXT, p_email TEXT) RETURNS VOID`
- `g011_hash(p_hash TEXT) RETURNS VOID`
- `g011_otro_admin(p_usuario INTEGER) RETURNS BOOLEAN`
- `g011_proteger_usuario() RETURNS TRIGGER`
- `g011_proteger_rol() RETURNS TRIGGER`
