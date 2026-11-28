# Firmas y retornos SQL — 010

Todos los parámetros son obligatorios; pasar NULL explícito solo donde se permite. Las funciones no son endpoints HTTP.

Las filas de retorno usan los tipos compuestos existentes del diccionario; no se agregan campos a 007 ni se envían claves al estudiante.

## Operaciones públicas

### crear_actividad

```sql
public.crear_actividad(
    p_actor INTEGER,
    p_seccion INTEGER,
    p_tema INTEGER,
    p_titulo TEXT,
    p_instrucciones TEXT,
    p_finalidad TEXT,
    p_dificultad TEXT,
    p_max_intentos INTEGER,
    p_duracion_minutos INTEGER,
    p_desde TIMESTAMPTZ,
    p_hasta TIMESTAMPTZ
) RETURNS public.actividades
```

### listar_actividades_gestion

```sql
public.listar_actividades_gestion(
    p_actor INTEGER,
    p_seccion INTEGER,
    p_tema INTEGER
) RETURNS SETOF public.actividades
```

### obtener_actividad_gestion

```sql
public.obtener_actividad_gestion(
    p_actor INTEGER,
    p_actividad INTEGER
) RETURNS public.actividades
```

### actualizar_actividad

```sql
public.actualizar_actividad(
    p_actor INTEGER,
    p_actividad INTEGER,
    p_titulo TEXT,
    p_instrucciones TEXT,
    p_finalidad TEXT,
    p_dificultad TEXT,
    p_max_intentos INTEGER,
    p_duracion_minutos INTEGER,
    p_desde TIMESTAMPTZ,
    p_hasta TIMESTAMPTZ
) RETURNS public.actividades
```

### publicar_actividad

```sql
public.publicar_actividad(
    p_actor INTEGER,
    p_actividad INTEGER
) RETURNS public.actividades
```

### cambiar_estado_actividad

```sql
public.cambiar_estado_actividad(
    p_actor INTEGER,
    p_actividad INTEGER,
    p_estado TEXT
) RETURNS public.actividades
```

### eliminar_actividad

```sql
public.eliminar_actividad(
    p_actor INTEGER,
    p_actividad INTEGER
) RETURNS INTEGER
```

### crear_pregunta

```sql
public.crear_pregunta(
    p_actor INTEGER,
    p_actividad INTEGER,
    p_enunciado TEXT,
    p_tipo TEXT,
    p_orden INTEGER,
    p_puntaje NUMERIC,
    p_explicacion TEXT
) RETURNS public.preguntas
```

### listar_preguntas_gestion

```sql
public.listar_preguntas_gestion(
    p_actor INTEGER,
    p_actividad INTEGER
) RETURNS SETOF public.preguntas
```

### obtener_pregunta_gestion

```sql
public.obtener_pregunta_gestion(
    p_actor INTEGER,
    p_pregunta INTEGER
) RETURNS public.preguntas
```

### actualizar_pregunta

```sql
public.actualizar_pregunta(
    p_actor INTEGER,
    p_pregunta INTEGER,
    p_enunciado TEXT,
    p_tipo TEXT,
    p_orden INTEGER,
    p_puntaje NUMERIC,
    p_explicacion TEXT
) RETURNS public.preguntas
```

### eliminar_pregunta

```sql
public.eliminar_pregunta(
    p_actor INTEGER,
    p_pregunta INTEGER
) RETURNS INTEGER
```

### crear_opcion_respuesta

```sql
public.crear_opcion_respuesta(
    p_actor INTEGER,
    p_pregunta INTEGER,
    p_texto TEXT,
    p_orden INTEGER,
    p_correcta BOOLEAN
) RETURNS public.opciones_respuestas
```

### listar_opciones_gestion

```sql
public.listar_opciones_gestion(
    p_actor INTEGER,
    p_pregunta INTEGER
) RETURNS SETOF public.opciones_respuestas
```

### obtener_opcion_gestion

```sql
public.obtener_opcion_gestion(
    p_actor INTEGER,
    p_opcion INTEGER
) RETURNS public.opciones_respuestas
```

### actualizar_opcion_respuesta

```sql
public.actualizar_opcion_respuesta(
    p_actor INTEGER,
    p_opcion INTEGER,
    p_texto TEXT,
    p_orden INTEGER,
    p_correcta BOOLEAN
) RETURNS public.opciones_respuestas
```

### eliminar_opcion_respuesta

```sql
public.eliminar_opcion_respuesta(
    p_actor INTEGER,
    p_opcion INTEGER
) RETURNS INTEGER
```

### reordenar_preguntas

```sql
public.reordenar_preguntas(
    p_actor INTEGER,
    p_padre INTEGER,
    p_ids INTEGER[]
) RETURNS SETOF public.preguntas
```

### reordenar_opciones

```sql
public.reordenar_opciones(
    p_actor INTEGER,
    p_padre INTEGER,
    p_ids INTEGER[]
) RETURNS SETOF public.opciones_respuestas
```

### duplicar_actividad

```sql
public.duplicar_actividad(
    p_actor INTEGER,
    p_origen INTEGER,
    p_seccion INTEGER,
    p_tema INTEGER,
    p_titulo TEXT,
    p_desde TIMESTAMPTZ,
    p_hasta TIMESTAMPTZ
) RETURNS public.actividades
```

## Auxiliares privados

Sin EXECUTE para plataforma_backend o PUBLIC.

- `g010_contexto(p_actor INTEGER, p_seccion INTEGER, p_tema INTEGER, p_escritura BOOLEAN) RETURNS VOID`
- `g010_actividad(p_actor INTEGER, p_id INTEGER, p_escritura BOOLEAN, p_borrador BOOLEAN) RETURNS public.actividades`
- `g010_padre(p_actor INTEGER, p_id INTEGER, p_opcion BOOLEAN, p_escritura BOOLEAN) RETURNS INTEGER`
- `g010_datos(p_titulo TEXT, p_instrucciones TEXT, p_finalidad TEXT, p_dificultad TEXT, p_max_intentos INTEGER, p_duracion_minutos INTEGER, p_desde TIMESTAMPTZ, p_hasta TIMESTAMPTZ) RETURNS VOID`
- `g010_pregunta_datos(p_enunciado TEXT, p_tipo TEXT, p_orden INTEGER, p_puntaje NUMERIC, p_explicacion TEXT) RETURNS VOID`
- `g010_opcion_datos(p_texto TEXT, p_orden INTEGER, p_correcta BOOLEAN) RETURNS VOID`
- `g010_proteger_borrado() RETURNS TRIGGER`
