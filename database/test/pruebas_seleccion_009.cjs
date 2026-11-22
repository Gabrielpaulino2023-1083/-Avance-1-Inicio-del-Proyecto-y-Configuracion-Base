'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { seleccionarActividad } = require('../docs/ejemplos/seleccion_actividad.cjs');
const fila = (id, nivel, ref = 'MEDIA', refId=9) => ({actividad_id:id,titulo:'Actividad '+id,dificultad:nivel,actividad_referencia_id:refId,dificultad_referencia:ref});
for (const [ajuste,esperado] of [['reduced','BAJA'],['current','MEDIA'],['increased','ALTA']]) {
 test(ajuste+' desde MEDIA',()=>assert.equal(seleccionarActividad([fila(3,'ALTA'),fila(2,'MEDIA'),fila(1,'BAJA')],ajuste).dificultad,esperado));
}
test('limite inferior',()=>assert.equal(seleccionarActividad([fila(1,'BAJA','BAJA')],'reduced').dificultadObjetivo,'BAJA'));
test('limite superior',()=>assert.equal(seleccionarActividad([fila(1,'ALTA','ALTA')],'increased').dificultadObjetivo,'ALTA'));
test('empate favorece nivel inferior',()=>assert.equal(seleccionarActividad([fila(3,'ALTA'),fila(1,'BAJA')],'current').actividadId,1));
test('nivel cercano sin exacto',()=>{const x=seleccionarActividad([fila(2,'MEDIA'),fila(3,'ALTA')],'reduced');assert.equal(x.actividadId,2);assert.equal(x.coincideNivel,false);});
test('otra actividad antes de repetir referencia',()=>{const x=seleccionarActividad([fila(9,'MEDIA'),fila(2,'ALTA')],'current');assert.equal(x.actividadId,2);assert.equal(x.coincideNivel,false);});
test('solo referencia permite repetir',()=>assert.equal(seleccionarActividad([fila(9,'MEDIA')],'current').esRepeticion,true));
test('desempate por ID',()=>assert.equal(seleccionarActividad([fila(7,'BAJA'),fila(2,'BAJA')],'reduced').actividadId,2));
test('vacio conserva recomendacion del tema',()=>assert.equal(seleccionarActividad([],'current'),null));
test('ajuste desconocido no se interpreta como current',()=>assert.throws(()=>seleccionarActividad([],'desconocido'),TypeError));
test('mezcla de referencias rechazada',()=>assert.throws(()=>seleccionarActividad([fila(1,'BAJA'),fila(2,'ALTA','ALTA')],'current'),TypeError));
test('referencia sin clasificar rechazada',()=>assert.throws(()=>seleccionarActividad([fila(1,'BAJA',null)],'current'),TypeError));
test('entrada no se ordena ni muta',()=>{const a=[fila(3,'ALTA'),fila(1,'BAJA')];const antes=JSON.stringify(a);seleccionarActividad(a,'current');assert.equal(JSON.stringify(a),antes);});
