'use strict';
const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');
const { setTimeout: delay } = require('node:timers/promises');
const {configuracionPrueba,comprobarEntorno}=require('./comprobar_entorno_concurrencia.cjs');
const cfg=configuracionPrueba('011');
const pg=process.env.BD011_PG_MODULE ? require(process.env.BD011_PG_MODULE) : createRequire(path.resolve('backend/package.json'))('pg');
const owner=new pg.Client(cfg),a=new pg.Client(cfg),b=new pg.Client(cfg),connected=[];
const hash='$2b$10$'+'A'.repeat(53); // Fixture estructural: sin contraseña de login.
const ok=(v,m)=>{if(!v)throw Error(m);console.log('OK CONCURRENCIA 011:',m);};
async function waitBlocked(pid,done){const end=Date.now()+4000;while(Date.now()<end){if((await owner.query('SELECT cardinality(pg_blocking_pids($1))>0 v',[pid])).rows[0].v)return;if(done())throw Error('La segunda operacion no espero el bloqueo.');await delay(25);}throw Error('No se observo bloqueo.');}
async function race(label,first,sql,params,code){
 await a.query('BEGIN');await first();await b.query('BEGIN');let done=false;
 const pending=b.query(sql,params).then(value=>({value}),error=>({error})).finally(()=>{done=true;});
 try{await waitBlocked(b.processID,()=>done);await a.query('COMMIT');const r=await pending;
 if(code){ok(r.error?.code===code,`${label}: ${r.error?.code||'sin error'}, esperado ${code}`);await b.query('ROLLBACK');}
 else{if(r.error)throw r.error;await b.query('COMMIT');ok(true,label);}
 }finally{await a.query('ROLLBACK').catch(()=>{});await b.query('ROLLBACK').catch(()=>{});await pending;}
}
(async()=>{try{
 for(const c of [owner,a,b]){await c.connect();connected.push(c);}

    for(const c of connected) await c.query('SET search_path=pg_catalog,public');
    await comprobarEntorno(owner,'011',["public.registrar_estudiante(TEXT,TEXT,TEXT,TEXT)", "public.crear_usuario_admin(INTEGER,TEXT,TEXT,TEXT,TEXT,TEXT)", "public.listar_usuarios_admin(INTEGER,BOOLEAN,TEXT,TEXT,INTEGER,INTEGER)", "public.obtener_usuario(INTEGER,INTEGER)", "public.actualizar_usuario_admin(INTEGER,INTEGER,TEXT,TEXT,TEXT)", "public.actualizar_mi_perfil(INTEGER,TEXT,TEXT)", "public.cambiar_estado_usuario_admin(INTEGER,INTEGER,BOOLEAN)", "public.asignar_rol_usuario(INTEGER,INTEGER,TEXT)", "public.desactivar_rol_usuario(INTEGER,INTEGER,TEXT)", "public.cambiar_rol_academico(INTEGER,INTEGER,TEXT)", "public.actualizar_hash_usuario(INTEGER,INTEGER,TEXT)"]);

 if(Number((await owner.query('SELECT count(*) n FROM public.usuarios')).rows[0].n)!==0)throw Error('La base debe estar SIN usuarios. Crear otra base independiente sin seeds.');
 await owner.query("INSERT INTO public.roles(codigo,nombre) VALUES('ADMINISTRADOR','Administrador'),('DOCENTE','Docente'),('ESTUDIANTE','Estudiante') ON CONFLICT(codigo) DO NOTHING");
 const admins=[];
 for(const n of [1,2]){const id=(await owner.query("INSERT INTO public.usuarios(nombre,apellido,email,password_hash) VALUES('Admin','QA',$1,'FICTICIO_NO_LOGIN') RETURNING id",[`admin${n}-concurrencia011@example.com`])).rows[0].id;await owner.query("INSERT INTO public.usuario_roles(usuario_id,rol_id,asignado_por) SELECT $1,id,$1 FROM public.roles WHERE codigo='ADMINISTRADOR'",[id]);admins.push(id);}
 const [ad1,ad2]=admins;
 await race('Desactivar dos administradores conserva uno',()=>a.query('UPDATE public.usuarios SET activo=FALSE WHERE id=$1',[ad1]),'UPDATE public.usuarios SET activo=FALSE WHERE id=$1',[ad2],'55000');
 ok(Number((await owner.query("SELECT count(*) n FROM public.usuarios u JOIN public.usuario_roles ur ON ur.usuario_id=u.id AND ur.activo JOIN public.roles r ON r.id=ur.rol_id WHERE u.activo AND r.codigo='ADMINISTRADOR'")).rows[0].n)===1,'un administrador efectivo permanece');
 await owner.query('UPDATE public.usuarios SET activo=TRUE WHERE id=$1',[ad1]);
 await race('Desactivar los dos roles conserva uno',()=>a.query("UPDATE public.usuario_roles SET activo=FALSE,desactivado_en=clock_timestamp() WHERE usuario_id=$1 AND rol_id=(SELECT id FROM public.roles WHERE codigo='ADMINISTRADOR')",[ad1]),"UPDATE public.usuario_roles SET activo=FALSE,desactivado_en=clock_timestamp() WHERE usuario_id=$1 AND rol_id=(SELECT id FROM public.roles WHERE codigo='ADMINISTRADOR')",[ad2],'55000');
 await owner.query("UPDATE public.usuario_roles SET activo=TRUE,desactivado_en=NULL WHERE usuario_id=$1 AND rol_id=(SELECT id FROM public.roles WHERE codigo='ADMINISTRADOR')",[ad1]);
 const target=(await owner.query("INSERT INTO public.usuarios(nombre,apellido,email,password_hash) VALUES('Usuario','QA','sin-rol-concurrencia011@example.com','FICTICIO_NO_LOGIN') RETURNING id")).rows[0].id;
 await a.query('SET ROLE plataforma_backend');await b.query('SET ROLE plataforma_backend');
 await race('Asignacion academica opuesta serializada',()=>a.query("SELECT public.asignar_rol_usuario($1,$2,'ESTUDIANTE')",[ad2,target]),"SELECT public.asignar_rol_usuario($1,$2,'DOCENTE')",[ad2,target],'55000');
 ok((await owner.query('SELECT roles_activos FROM public.obtener_usuario($1,$2)',[ad2,target])).rows[0].roles_activos.join(',')==='ESTUDIANTE','no existen dos roles academicos simultaneos');
 await race('Registro duplicado concurrente',()=>a.query("SELECT public.registrar_estudiante('Registro','QA','registro-concurrencia011@example.com',$1)",[hash]),"SELECT public.registrar_estudiante('Registro','QA','REGISTRO-CONCURRENCIA011@example.com',$1)",[hash],'23505');
 ok(Number((await owner.query("SELECT count(*) n FROM public.usuarios WHERE lower(email)='registro-concurrencia011@example.com'")).rows[0].n)===1,'un solo registro confirmado');
 await race('Bloquear cuenta impide cambio de perfil posterior',()=>a.query('SELECT public.cambiar_estado_usuario_admin($1,$2,FALSE)',[ad2,target]),"SELECT public.actualizar_mi_perfil($1,'No autorizado','QA')",[target],'42501');
 ok((await owner.query('SELECT nombre FROM public.usuarios WHERE id=$1',[target])).rows[0].nombre==='Usuario','no cambia el perfil tras bloquear la cuenta');
 console.log('PRUEBAS CONCURRENCIA 011 COMPLETADAS: cinco carreras y cuatro comprobaciones.');
 console.log('Fixtures conservados en la base aislada. No usar sus cuentas para login ni reutilizar esta base para repetir la prueba.');
}catch(e){console.error(e.code||'',e.message);process.exitCode=1;}finally{for(const c of connected)await c.query('ROLLBACK').catch(()=>{});await Promise.allSettled(connected.map(c=>c.end()));}})();
