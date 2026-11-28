'use strict';
const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');
const { setTimeout: delay } = require('node:timers/promises');
const {configuracionPrueba,comprobarEntorno}=require('./comprobar_entorno_concurrencia.cjs');
const cfg=configuracionPrueba('010');
const pg = process.env.BD010_PG_MODULE
  ? require(process.env.BD010_PG_MODULE)
  : createRequire(path.resolve('backend/package.json'))('pg');
const owner = new pg.Client(cfg), a = new pg.Client(cfg), b = new pg.Client(cfg);
let ids, fixtureCommitted = false;
const connected = [];
const ok = (b, m) => { if (!b) throw Error(m); console.log('OK CONCURRENCIA 010:', m); };
async function blocked(pid, done) {
  const until = Date.now() + 4000;
  while (Date.now() < until) {
    const { rows } = await owner.query('SELECT cardinality(pg_blocking_pids($1))>0 bloqueado', [pid]);
    if (rows[0].bloqueado) return;
    if (done()) throw Error('La operacion concurrente termino sin esperar el bloqueo esperado.');
    await delay(25);
  }
  throw Error('No se observo la espera por bloqueo dentro del plazo.');
}
async function race(label, first, secondSQL, params, expectedCode) {
  await a.query('BEGIN'); await first(); await b.query('BEGIN');
  let finished = false;
  const pending = b.query(secondSQL, params).then(value => ({ value }), error => ({ error })).finally(() => { finished = true; });
  try {
    await blocked(b.processID, () => finished);
    await a.query('COMMIT');
    const result = await pending;
    if (expectedCode) {
      ok(result.error?.code === expectedCode, `${label}: esperado ${expectedCode}, recibido ${result.error?.code || 'exito'}`);
      await b.query('ROLLBACK');
    } else {
      if (result.error) throw result.error;
      await b.query('COMMIT'); ok(true, label + ': serializacion correcta');
    }
  } finally {
    await a.query('ROLLBACK').catch(() => {});
    await b.query('ROLLBACK').catch(() => {});
    await pending;
  }
}
async function activity(title, published = false) {
  const { rows } = await a.query("SELECT * FROM public.crear_actividad($1::integer,$2::integer,$3::integer,$4::text,'I'::text,'PRACTICA'::text,'BAJA'::text,5::integer,30::integer,now()-interval '1 minute',now()+interval '1 day')", [ids.docente, ids.seccion, ids.tema, title]);
  const act = rows[0].id;
  const q = (await a.query("SELECT * FROM public.crear_pregunta($1,$2,'Pregunta','SELECCION_UNICA',1,10,NULL)", [ids.docente, act])).rows[0].id;
  await a.query("SELECT public.crear_opcion_respuesta($1,$2,'A',1,TRUE)", [ids.docente, q]);
  await a.query("SELECT public.crear_opcion_respuesta($1,$2,'B',2,FALSE)", [ids.docente, q]);
  if (published) await a.query('SELECT public.publicar_actividad($1,$2)', [ids.docente, act]);
  return { act, q };
}
async function cleanup() {
  if (!fixtureCommitted || !ids) return;
  await owner.query('BEGIN');
  try {
    const acts = (await owner.query('SELECT a.id FROM public.actividades a JOIN public.secciones s ON s.id=a.seccion_id JOIN public.ediciones_curso e ON e.id=s.edicion_id WHERE e.curso_id=$1', [ids.curso])).rows.map(r => r.id);
    const it = (await owner.query('SELECT id FROM public.intentos WHERE actividad_id=ANY($1::integer[])', [acts])).rows.map(r => r.id);
    await owner.query('DELETE FROM public.respuesta_opciones o USING public.respuestas r WHERE o.respuesta_id=r.id AND r.intento_id=ANY($1::integer[])', [it]);
    await owner.query('DELETE FROM public.respuestas WHERE intento_id=ANY($1::integer[])', [it]);
    await owner.query('DELETE FROM public.intentos WHERE id=ANY($1::integer[])', [it]);
    await owner.query("UPDATE public.actividades SET estado='BORRADOR' WHERE id=ANY($1::integer[])", [acts]);
    await owner.query('DELETE FROM public.opciones_respuestas o USING public.preguntas p WHERE o.pregunta_id=p.id AND p.actividad_id=ANY($1::integer[])', [acts]);
    await owner.query('DELETE FROM public.preguntas WHERE actividad_id=ANY($1::integer[])', [acts]);
    await owner.query('DELETE FROM public.actividades WHERE id=ANY($1::integer[])', [acts]);
    await owner.query('DELETE FROM public.temas WHERE modulo_id=$1', [ids.modulo]);
    await owner.query('DELETE FROM public.modulos WHERE id=$1', [ids.modulo]);
    await owner.query('DELETE FROM public.inscripciones WHERE edicion_id=$1', [ids.edicion]);
    await owner.query('DELETE FROM public.seccion_docentes WHERE seccion_id IN (SELECT id FROM public.secciones WHERE edicion_id=$1)', [ids.edicion]);
    await owner.query('DELETE FROM public.secciones WHERE edicion_id=$1', [ids.edicion]);
    await owner.query('DELETE FROM public.ediciones_curso WHERE id=$1', [ids.edicion]);
    await owner.query('DELETE FROM public.curso_editores WHERE curso_id=$1', [ids.curso]);
    await owner.query('DELETE FROM public.cursos WHERE id=$1', [ids.curso]);
    const users = [ids.admin, ids.docente, ids.estudiante, ids.otro];
    await owner.query('DELETE FROM public.usuario_roles WHERE usuario_id=ANY($1::integer[])', [users]);
    await owner.query('DELETE FROM public.usuarios WHERE id=ANY($1::integer[])', [users]);
    await owner.query('COMMIT'); console.log('Fixtures concurrentes eliminados. Las secuencias pueden avanzar.');
  } catch (e) { await owner.query('ROLLBACK'); throw e; }
}
(async () => {
  try {
    await owner.connect(); connected.push(owner); await a.connect(); connected.push(a); await b.connect(); connected.push(b);

    for(const c of connected) await c.query('SET search_path=pg_catalog,public');
    await comprobarEntorno(owner,'010',["public.crear_actividad(INTEGER,INTEGER,INTEGER,TEXT,TEXT,TEXT,TEXT,INTEGER,INTEGER,TIMESTAMPTZ,TIMESTAMPTZ)", "public.listar_actividades_gestion(INTEGER,INTEGER,INTEGER)", "public.obtener_actividad_gestion(INTEGER,INTEGER)", "public.actualizar_actividad(INTEGER,INTEGER,TEXT,TEXT,TEXT,TEXT,INTEGER,INTEGER,TIMESTAMPTZ,TIMESTAMPTZ)", "public.publicar_actividad(INTEGER,INTEGER)", "public.cambiar_estado_actividad(INTEGER,INTEGER,TEXT)", "public.eliminar_actividad(INTEGER,INTEGER)", "public.crear_pregunta(INTEGER,INTEGER,TEXT,TEXT,INTEGER,NUMERIC,TEXT)", "public.listar_preguntas_gestion(INTEGER,INTEGER)", "public.obtener_pregunta_gestion(INTEGER,INTEGER)", "public.actualizar_pregunta(INTEGER,INTEGER,TEXT,TEXT,INTEGER,NUMERIC,TEXT)", "public.eliminar_pregunta(INTEGER,INTEGER)", "public.crear_opcion_respuesta(INTEGER,INTEGER,TEXT,INTEGER,BOOLEAN)", "public.listar_opciones_gestion(INTEGER,INTEGER)", "public.obtener_opcion_gestion(INTEGER,INTEGER)", "public.actualizar_opcion_respuesta(INTEGER,INTEGER,TEXT,INTEGER,BOOLEAN)", "public.eliminar_opcion_respuesta(INTEGER,INTEGER)", "public.reordenar_preguntas(INTEGER,INTEGER,INTEGER[])", "public.reordenar_opciones(INTEGER,INTEGER,INTEGER[])", "public.duplicar_actividad(INTEGER,INTEGER,INTEGER,INTEGER,TEXT,TIMESTAMPTZ,TIMESTAMPTZ)", "public.iniciar_intento(integer,integer,integer)", "public.inscribir_estudiante(integer,integer,integer)"]);

    const fixture = fs.readFileSync(path.join(__dirname, 'pruebas_migracion_010.sql'), 'utf8')
      .split('\n').filter(l => !l.trimStart().startsWith('\\')).join('\n').split('SET LOCAL ROLE plataforma_backend;')[0];
    await owner.query(fixture);
    ids = Object.fromEntries((await owner.query('SELECT k,v FROM contexto010')).rows.map(r => [r.k,r.v]));
    await owner.query('COMMIT'); fixtureCommitted = true;
    await a.query('SET ROLE plataforma_backend'); await b.query('SET ROLE plataforma_backend');
    const edit = await activity('Editar y publicar');
    await race('Editar antes de publicar', () => a.query("SELECT public.actualizar_pregunta($1,$2,'Editada','SELECCION_UNICA',1,10,NULL)", [ids.docente, edit.q]), 'SELECT public.publicar_actividad($1,$2)', [ids.docente, edit.act]);
    ok((await owner.query('SELECT enunciado FROM public.preguntas WHERE id=$1',[edit.q])).rows[0].enunciado==='Editada', 'publicacion conserva la edicion confirmada');
    const start = await activity('Iniciar y archivar', true);
    await race('Iniciar impide archivo concurrente', () => a.query('SELECT public.iniciar_intento($1,$2,$3)', [start.act, ids.inscripcion, ids.estudiante]), "SELECT public.cambiar_estado_actividad($1,$2,'ARCHIVADO')", [ids.docente, start.act], '55000');
    const pub = await activity('Publicar y agregar');
    await race('Publicar impide nueva pregunta concurrente', () => a.query('SELECT public.publicar_actividad($1,$2)', [ids.docente, pub.act]), "SELECT public.crear_pregunta($1,$2,'Tardia','SELECCION_UNICA',2,10,NULL)", [ids.docente, pub.act], '55000');
    const rev = await activity('Revocar asignacion');
    await a.query('RESET ROLE');
    await race('Revocacion antes de editar', () => a.query('UPDATE public.seccion_docentes SET activo=FALSE WHERE seccion_id=$1 AND usuario_id=$2', [ids.seccion, ids.docente]), "SELECT public.actualizar_pregunta($1,$2,'No autorizada','SELECCION_UNICA',1,10,NULL)", [ids.docente, rev.q], '42501');
    ok((await owner.query('SELECT enunciado FROM public.preguntas WHERE id=$1',[rev.q])).rows[0].enunciado==='Pregunta', 'edicion revocada no cambia contenido');
    console.log('PRUEBAS CONCURRENCIA 010 COMPLETADAS: cuatro carreras y dos verificaciones de contenido.');
  } catch (e) { console.error(e.code || '', e.message); process.exitCode = 1; }
  finally {
    for (const c of connected) await c.query('ROLLBACK').catch(() => {});
    await cleanup().catch(e => { console.error('No se pudieron limpiar fixtures:',e.message); process.exitCode=1; });
    await Promise.allSettled(connected.map(c => c.end()));
  }
})();
