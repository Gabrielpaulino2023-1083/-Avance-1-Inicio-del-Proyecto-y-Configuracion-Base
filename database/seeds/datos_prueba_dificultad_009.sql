\set ON_ERROR_STOP on
\encoding UTF8
\if :{?demo_email}
\else
 \set demo_email 'estudiante.demo@example.com'
\endif
-- Solo base local de revision. No altera DEMO-003 ni DEMO-SQL-007.
BEGIN;
SET LOCAL search_path=pg_catalog,public,pg_temp;
CREATE TEMP TABLE parametro009(email TEXT NOT NULL) ON COMMIT DROP;
INSERT INTO parametro009 VALUES(lower(btrim(:'demo_email')));
CREATE TEMP TABLE plantilla009(actividad_orden INTEGER,clave TEXT,nivel TEXT,titulo TEXT,
    pregunta_orden INTEGER,enunciado TEXT,opciones JSONB) ON COMMIT DROP;
INSERT INTO plantilla009 VALUES
(1,'REFERENCIA','MEDIA','Referencia: relacionar pedidos y clientes',1,'clientes contiene (1,Ana),(2,Luis). pedidos contiene (10,1),(11,1). Un LEFT JOIN de clientes con pedidos por cliente_id devuelve cuantas filas?','[{"texto": "Tres filas", "correcta": true}, {"texto": "Dos filas", "correcta": false}, {"texto": "Cuatro filas", "correcta": false}]'),
(1,'REFERENCIA','MEDIA','Referencia: relacionar pedidos y clientes',2,'En clientes LEFT JOIN pedidos ON clientes.id=pedidos.cliente_id, ¿que cliente se conserva sin pedido?','[{"texto": "Luis", "correcta": true}, {"texto": "Ninguno", "correcta": false}, {"texto": "Solo Ana", "correcta": false}]'),
(2,'BAJA','BAJA','Basico: significado de las uniones',1,'¿Que devuelve un INNER JOIN con condicion ON?','[{"texto": "Las combinaciones que cumplen la condicion", "correcta": true}, {"texto": "Todas las filas izquierdas siempre", "correcta": false}, {"texto": "Siempre el producto cartesiano", "correcta": false}]'),
(2,'BAJA','BAJA','Basico: significado de las uniones',2,'¿Que preserva un LEFT JOIN cuando no hay coincidencia derecha?','[{"texto": "La fila izquierda con NULL en columnas derechas", "correcta": true}, {"texto": "Solo la fila derecha", "correcta": false}, {"texto": "Ninguna fila", "correcta": false}]'),
(3,'MEDIA','MEDIA','Intermedio: calcular filas de una union',1,'clientes: IDs 1 y 2. pedidos: cliente_id 1,1,2. Un INNER JOIN por cliente_id produce cuantas filas?','[{"texto": "Tres", "correcta": true}, {"texto": "Dos", "correcta": false}, {"texto": "Seis", "correcta": false}]'),
(3,'MEDIA','MEDIA','Intermedio: calcular filas de una union',2,'clientes: IDs 1,2,3. pedidos: cliente_id 1,1,2. Un LEFT JOIN produce cuantas filas?','[{"texto": "Cuatro", "correcta": true}, {"texto": "Tres", "correcta": false}, {"texto": "Cinco", "correcta": false}]'),
(4,'ALTA','ALTA','Avanzado: agregacion y filtros de LEFT JOIN',1,'Un cliente sin pedidos se conserva por LEFT JOIN. Para contar sus pedidos en GROUP BY clientes.id, ¿que expresion devuelve cero? pedidos.id no admite NULL en la tabla.','[{"texto": "COUNT(pedidos.id)", "correcta": true}, {"texto": "COUNT(*)", "correcta": false}, {"texto": "COUNT(clientes.id)", "correcta": false}]'),
(4,'ALTA','ALTA','Avanzado: agregacion y filtros de LEFT JOIN',2,'Para conservar todos los clientes al unir solo pedidos activos, ¿donde colocar pedidos.activo=TRUE?','[{"texto": "En ON junto a la relacion de IDs", "correcta": true}, {"texto": "En WHERE despues del LEFT JOIN", "correcta": false}, {"texto": "En HAVING COUNT(*)=0", "correcta": false}]');
DO $seed$
DECLARE u INTEGER; ad INTEGER; c INTEGER; ed INTEGER; sec INTEGER; ins INTEGER;
 m INTEGER; t INTEGER; act INTEGER; pre INTEGER; it INTEGER; cod TEXT;
 hash_anterior TEXT; marca TEXT; descripcion_existente TEXT; k INTEGER; p RECORD; r RECORD;
BEGIN
 PERFORM pg_advisory_xact_lock(9009,2026);
 IF to_regprocedure('public.listar_candidatas_actividad(integer,integer,integer,integer)') IS NULL THEN
  RAISE EXCEPTION 'Aplicar 009 antes de cargar su demo.';
 END IF;
 SELECT id,password_hash INTO u,hash_anterior FROM usuarios
 WHERE lower(email)=(SELECT email FROM parametro009) AND activo FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Falta el estudiante demo activo; este seed no crea usuarios ni contrasenas.'; END IF;
 IF NOT EXISTS(SELECT 1 FROM usuario_roles ur JOIN roles ro ON ro.id=ur.rol_id
     WHERE ur.usuario_id=u AND ur.activo AND ro.codigo='ESTUDIANTE') THEN
  RAISE EXCEPTION 'Falta rol ESTUDIANTE activo.';
 END IF;
 marca:='DEMO_DIFICULTAD_009_V1; estudiante_id='||u;
 SELECT id,descripcion INTO c,descripcion_existente FROM cursos WHERE codigo='DEMO-DIFICULTAD-009' FOR UPDATE;
 IF FOUND THEN
  IF descripcion_existente IS DISTINCT FROM marca THEN RAISE EXCEPTION 'Colision del codigo demo; no se sobrescribe.'; END IF;
  IF (SELECT count(*) FROM actividades a JOIN secciones s ON s.id=a.seccion_id
      JOIN ediciones_curso e ON e.id=s.edicion_id WHERE e.curso_id=c
      AND a.titulo IN ('DEMO-009: Referencia: relacionar pedidos y clientes',
      'DEMO-009: Basico: significado de las uniones','DEMO-009: Intermedio: calcular filas de una union',
      'DEMO-009: Avanzado: agregacion y filtros de LEFT JOIN'))<>4
     OR NOT EXISTS(SELECT 1 FROM inscripciones i JOIN ediciones_curso e ON e.id=i.edicion_id
                   WHERE e.curso_id=c AND i.estudiante_id=u) THEN
    RAISE EXCEPTION 'Demo existente incompleta o modificada; no se reconstruye automaticamente.';
  END IF;
  RAISE NOTICE 'DEMO-DIFICULTAD-009 ya existe. No se cambian preguntas, niveles, intentos ni credenciales.';
  RETURN;
 END IF;
 SELECT x.id INTO ad FROM usuarios x JOIN usuario_roles ur ON ur.usuario_id=x.id AND ur.activo
 JOIN roles ro ON ro.id=ur.rol_id AND ro.codigo='ADMINISTRADOR' WHERE x.activo ORDER BY x.id LIMIT 1;
 IF ad IS NULL THEN RAISE EXCEPTION 'Falta administrador activo.'; END IF;
 INSERT INTO cursos(codigo,nombre,descripcion,estado,creado_por)
 VALUES('DEMO-DIFICULTAD-009','SQL JOIN: niveles de demostracion',marca,'ACTIVO',ad) RETURNING id INTO c;
 INSERT INTO ediciones_curso(curso_id,codigo,nombre,fecha_inicio,fecha_fin,
    inscripcion_desde,inscripcion_hasta,estado,creado_por)
 VALUES(c,'ED-009','Demo dificultad',now()-interval '1 day',now()+interval '1 year',
    now()-interval '1 day',now()+interval '1 year','ABIERTA',ad) RETURNING id INTO ed;
 INSERT INTO secciones(edicion_id,codigo,cupo_maximo,estado,creado_por)
 VALUES(ed,'SEC-009',30,'ABIERTA',ad) RETURNING id INTO sec;
 SELECT id INTO ins FROM inscribir_estudiante(sec,u,ad);
 INSERT INTO modulos(curso_id,nombre,descripcion,orden,estado,creado_por)
 VALUES(c,'Uniones por niveles','Niveles de demostracion pendientes de validacion pedagogica.',1,'PUBLICADO',ad) RETURNING id INTO m;
 INSERT INTO temas(modulo_id,nombre,descripcion,orden,estado,creado_por)
 VALUES(m,'SQL JOIN (demo dificultad)','Conceptos, cardinalidad y agregacion.',1,'PUBLICADO',ad) RETURNING id INTO t;
 FOR k IN 1..4 LOOP
  SELECT * INTO STRICT p FROM plantilla009 WHERE actividad_orden=k AND pregunta_orden=1;
  INSERT INTO actividades(seccion_id,tema_id,titulo,instrucciones,finalidad,dificultad,
      duracion_minutos,max_intentos,disponible_desde,disponible_hasta,creado_por)
  VALUES(sec,t,'DEMO-009: '||p.titulo,'Responde ambas preguntas de seleccion unica.',
      'PRACTICA',p.nivel,30,3,now()-interval '1 hour',now()+interval '1 year',ad) RETURNING id INTO act;
  FOR p IN SELECT * FROM plantilla009 WHERE actividad_orden=k ORDER BY pregunta_orden LOOP
   INSERT INTO preguntas(actividad_id,enunciado,orden,puntaje_maximo)
   VALUES(act,p.enunciado,p.pregunta_orden,10) RETURNING id INTO pre;
   INSERT INTO opciones_respuestas(pregunta_id,texto,orden,es_correcta)
   SELECT pre,o.valor->>'texto',o.n::INTEGER,(o.valor->>'correcta')::BOOLEAN
   FROM jsonb_array_elements(p.opciones) WITH ORDINALITY o(valor,n);
  END LOOP;
  UPDATE actividades SET estado='PUBLICADO' WHERE id=act;
  IF k=1 THEN
   it:=iniciar_intento(act,ins,u);
   FOR r IN SELECT id,pregunta_id FROM respuestas WHERE intento_id=it LOOP
    SELECT id INTO pre FROM opciones_respuestas WHERE pregunta_id=r.pregunta_id AND orden=2;
    PERFORM guardar_opciones_respuesta(r.id,u,ARRAY[pre]);
   END LOOP;
   PERFORM entregar_intento(it,u);PERFORM calificar_intento(it);
   IF (SELECT puntaje_obtenido FROM intentos WHERE id=it)<>0 THEN RAISE EXCEPTION 'Referencia demo no calificada en cero.'; END IF;
  END IF;
 END LOOP;
 IF (SELECT password_hash FROM usuarios WHERE id=u) IS DISTINCT FROM hash_anterior THEN RAISE EXCEPTION 'Credencial modificada inesperadamente.'; END IF;
 RAISE NOTICE 'Demo creada: curso %, inscripcion %, tema %. Referencia MEDIA calificada en 0/20; tres candidatas nuevas.',c,ins,t;
END;
$seed$;
SELECT u.email,i.id AS inscripcion_id,t.id AS tema_id,a.id AS actividad_id,a.titulo,a.dificultad,
       coalesce(ra.intentos_calificados,0) AS intentos_calificados,ra.promedio_porcentaje
FROM usuarios u JOIN inscripciones i ON i.estudiante_id=u.id
JOIN ediciones_curso e ON e.id=i.edicion_id JOIN cursos c ON c.id=e.curso_id
JOIN actividades a ON a.seccion_id=i.seccion_id JOIN temas t ON t.id=a.tema_id
LEFT JOIN resultados_actividades ra ON ra.inscripcion_id=i.id AND ra.actividad_id=a.id
WHERE c.codigo='DEMO-DIFICULTAD-009' AND lower(u.email)=(SELECT email FROM parametro009)
ORDER BY a.id;
COMMIT;
