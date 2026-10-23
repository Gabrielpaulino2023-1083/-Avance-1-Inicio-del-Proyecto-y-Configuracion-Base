SELECT
    has_table_privilege(
        'plataforma_backend',
        'public.intentos',
        'INSERT'
    ) AS puede_insertar_intentos,

    has_table_privilege(
        'plataforma_backend',
        'public.respuestas',
        'UPDATE'
    ) AS puede_modificar_respuestas,

    has_table_privilege(
        'plataforma_backend',
        'public.respuesta_opciones',
        'DELETE'
    ) AS puede_eliminar_selecciones,

    has_function_privilege(
        'plataforma_backend',
        'public.iniciar_intento(integer,integer,integer)',
        'EXECUTE'
    ) AS puede_iniciar_mediante_funcion;