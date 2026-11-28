'use strict';
function configuracionPrueba(version) {
  const database=(process.env.DB_NAME||'').trim();
  const flag=`BD${version}_VALIDACION_AISLADA`;
  if(!database) throw Error(`Falta DB_NAME. Las instrucciones anteriores podian usar $baseNueva sin definir. Use el lanzador ejecutar_concurrencia_010_011.ps1.`);
  if(!/validacion|revision|test|prueba/i.test(database)) throw Error(`DB_NAME=${database}: esta prueba exige una base independiente de validacion/revision/test/prueba. No cambie esta proteccion para usar desarrollo.`);
  if(process.env[flag]!=='SI') throw Error(`Falta ${flag}=SI para la prueba ${version}. Cada prueba usa su propia confirmacion. Use el lanzador.`);
  const port=Number(process.env.DB_PORT||5432);
  if(!Number.isInteger(port)||port<1||port>65535)throw Error('DB_PORT no es valido.');
  return {host:process.env.DB_HOST||'localhost',port,database,user:process.env.DB_USER||'postgres',password:process.env.DB_PASSWORD,connectionTimeoutMillis:5000,statement_timeout:10000,application_name:`concurrencia${version}`};
}
async function comprobarEntorno(owner,version,firmas) {
  const {rows:[info]}=await owner.query("SELECT current_database() base,current_user usuario,current_setting('search_path') search_path,version() servidor,(SELECT rolsuper FROM pg_roles WHERE rolname=current_user) superusuario");
  console.log(`Destino ${version}: base=${info.base}; usuario=${info.usuario}; search_path=${info.search_path}`);
  console.log(`Servidor: ${info.servidor}`);
  const missing=(await owner.query('SELECT f FROM unnest($1::text[]) f WHERE to_regprocedure(f) IS NULL',[firmas])).rows.map(x=>x.f);
  if(missing.length)throw Error(`PREVALIDACION ${version}: la base ${info.base} no contiene las firmas requeridas: ${missing.join('; ')}. No se crearon fixtures. Use una base nueva instalada con instalar_revision_${version}.sql; no reinstale sobre una base ya completada.`);
  if(!info.superusuario)throw Error('La preparacion de fixtures requiere la cuenta instaladora superusuario (habitualmente postgres), no plataforma_backend. Las operaciones bajo prueba se ejecutan internamente como plataforma_backend.');
  if(version==='010'){
    const {rows:[r]}=await owner.query("SELECT to_regprocedure('public.registrar_estudiante(text,text,text,text)') IS NOT NULL tiene011");
    if(r.tiene011)throw Error('La carrera 010 debe ejecutarse en una base aislada instalada SOLO hasta 010. La 011 protege al ultimo administrador y cambia la limpieza de fixtures. El lanzador prepara bases separadas. No quite triggers.');
  }
}
module.exports={configuracionPrueba,comprobarEntorno};
