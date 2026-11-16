// CRUD de cursos (administrador) y de módulos y temas (docente/administrador)
// por la API real. Cada operación se verifica también directamente en PostgreSQL.
import { test, describe, before, after } from "node:test";
import assert from "node:assert/strict";
import { checkDatabase } from "../config.mjs";
import { iniciarServidor, ordenUnico } from "../helpers/servidor.mjs";

const dbProblem = await checkDatabase();
const BLOCKED = dbProblem ? `BLOQUEADO: ${dbProblem}` : false;
let srv;
const sufijo = Date.now().toString(36).toUpperCase();
const fila = async (sql, params) => (await srv.admin.query(sql, params)).rows[0];

before(async () => { if (!BLOCKED) srv = await iniciarServidor(); });
after(async () => { if (!BLOCKED) await srv.cerrar(); });

describe("CRUD de cursos (administrador)", { skip: BLOCKED }, () => {
  let A;
  let curso;
  before(async () => { A = await srv.sesion("ADMINISTRADOR"); });

  test("CP-CUR-01 crear curso y guardarlo en PostgreSQL", async () => {
    const r = await srv.api("POST", "/api/cursos", {
      token: A.token,
      body: { codigo: `QA-${sufijo}`, nombre: "Curso de QA", descripcion: "Creado por las pruebas automatizadas" },
    });
    assert.equal(r.status, 201, JSON.stringify(r.data));
    curso = r.data.data;
    assert.equal(curso.codigo, `QA-${sufijo}`);
    assert.equal(curso.creadoPor, A.user.id);
    const db = await fila("SELECT codigo, nombre, estado, creado_por FROM cursos WHERE id = $1", [curso.id]);
    assert.equal(db.nombre, "Curso de QA");
    assert.equal(db.creado_por, A.user.id);
    assert.equal(db.estado, curso.estado);
  });

  test("CP-CUR-02 listar, filtrar y consultar cursos", async () => {
    const lista = await srv.api("GET", "/api/cursos?limite=100", { token: A.token });
    assert.equal(lista.status, 200);
    assert.ok(lista.data.data.some((c) => c.id === curso.id));
    const filtro = await srv.api("GET", `/api/cursos?estado=${curso.estado}&limite=100`, { token: A.token });
    assert.ok(filtro.data.data.every((c) => c.estado === curso.estado));
    const uno = await srv.api("GET", `/api/cursos/${curso.id}`, { token: A.token });
    assert.equal(uno.status, 200);
    assert.equal(uno.data.data.codigo, curso.codigo);
  });

  test("CP-CUR-03 actualizar curso y persistir el cambio", async () => {
    const r = await srv.api("PUT", `/api/cursos/${curso.id}`, {
      token: A.token,
      body: { codigo: `QA-${sufijo}`, nombre: "Curso de QA (editado)", descripcion: "Descripción actualizada" },
    });
    assert.equal(r.status, 200, JSON.stringify(r.data));
    const db = await fila("SELECT nombre, descripcion FROM cursos WHERE id = $1", [curso.id]);
    assert.equal(db.nombre, "Curso de QA (editado)");
    assert.equal(db.descripcion, "Descripción actualizada");
  });

  test("CP-CUR-04 archivar curso (baja lógica) y bloquear cambios posteriores", async () => {
    // Regla documentada (backend/README.md): eliminar = ARCHIVADO; un curso archivado
    // no se puede editar ni reactivar.
    const r = await srv.api("PATCH", `/api/cursos/${curso.id}/estado`, { token: A.token, body: { estado: "ARCHIVADO" } });
    assert.equal(r.status, 200, JSON.stringify(r.data));
    assert.equal((await fila("SELECT estado FROM cursos WHERE id = $1", [curso.id])).estado, "ARCHIVADO");
    assert.ok(await fila("SELECT id FROM cursos WHERE id = $1", [curso.id]), "el registro se conserva");
    const reactivar = await srv.api("PATCH", `/api/cursos/${curso.id}/estado`, { token: A.token, body: { estado: "ACTIVO" } });
    assert.equal(reactivar.status, 409);
    const editar = await srv.api("PUT", `/api/cursos/${curso.id}`, {
      token: A.token, body: { codigo: `QA-${sufijo}`, nombre: "No", descripcion: "No" },
    });
    assert.equal(editar.status, 409);
    assert.equal((await fila("SELECT estado FROM cursos WHERE id = $1", [curso.id])).estado, "ARCHIVADO");
  });

  test("CP-CUR-05 código de curso duplicado", async () => {
    const r = await srv.api("POST", "/api/cursos", {
      token: A.token, body: { codigo: `QA-${sufijo}`, nombre: "Otro", descripcion: "Duplicado" },
    });
    assert.equal(r.status, 409);
    const { rows } = await srv.admin.query("SELECT COUNT(*)::int n FROM cursos WHERE codigo = $1", [`QA-${sufijo}`]);
    assert.equal(rows[0].n, 1);
  });

  test("CP-CUR-06 datos inválidos e ids inexistentes", async () => {
    const valido = { codigo: `QB-${sufijo}`, nombre: "N", descripcion: "D" };
    const casos = [
      ["POST", "/api/cursos", { ...valido, codigo: "" }, 400],
      ["POST", "/api/cursos", { ...valido, nombre: "x".repeat(151) }, 400],
      ["POST", "/api/cursos", { ...valido, descripcion: "   " }, 400],
      ["PATCH", `/api/cursos/${curso.id}/estado`, { estado: "ELIMINADO" }, 400],
      ["GET", "/api/cursos/abc", undefined, 400],
      ["GET", "/api/cursos/99999999", undefined, 404],
      ["GET", "/api/cursos?limite=0", undefined, 400],
      ["GET", "/api/cursos?estado=XYZ", undefined, 400],
    ];
    const errores = [];
    for (const [m, ruta, body, esperado] of casos) {
      const r = await srv.api(m, ruta, { token: A.token, body });
      if (r.status !== esperado) errores.push(`${m} ${ruta} ${JSON.stringify(body)} → ${r.status} (esperado ${esperado})`);
    }
    assert.deepEqual(errores, []);
  });
});

describe("CRUD de módulos y temas (docente del curso DEMO-006)", { skip: BLOCKED }, () => {
  let D;
  let cursoId;
  let modulo;
  let tema;
  before(async () => {
    D = await srv.sesion("DOCENTE");
    cursoId = (await fila("SELECT id FROM cursos WHERE codigo = 'DEMO-006'")).id;
  });

  test("CP-MT-01 crear módulo (BORRADOR por defecto) y guardarlo", async () => {
    const r = await srv.api("POST", "/api/modulos", {
      token: D.token,
      body: { cursoId, nombre: `Módulo QA ${sufijo}`, descripcion: "Creado por QA", orden: ordenUnico() },
    });
    assert.equal(r.status, 201, JSON.stringify(r.data));
    modulo = r.data.data;
    assert.equal(modulo.estado, "BORRADOR");
    const db = await fila("SELECT curso_id, nombre, estado, creado_por FROM modulos WHERE id = $1", [modulo.id]);
    assert.equal(db.curso_id, cursoId);
    assert.equal(db.creado_por, D.user.id);
  });

  test("CP-MT-02 listar y actualizar módulo", async () => {
    const lista = await srv.api("GET", `/api/modulos?cursoId=${cursoId}`, { token: D.token });
    assert.equal(lista.status, 200);
    assert.ok(lista.data.data.some((m) => m.id === modulo.id));
    const r = await srv.api("PUT", `/api/modulos/${modulo.id}`, {
      token: D.token,
      body: { nombre: `Módulo QA ${sufijo} (editado)`, descripcion: "Editado", orden: modulo.orden },
    });
    assert.equal(r.status, 200, JSON.stringify(r.data));
    assert.equal(r.data.data.estado, "BORRADOR", "sin estado en el cuerpo, conserva el actual");
    assert.equal((await fila("SELECT nombre FROM modulos WHERE id = $1", [modulo.id])).nombre, `Módulo QA ${sufijo} (editado)`);
  });

  test("CP-MT-03 orden de módulo duplicado en el mismo curso", async () => {
    const r = await srv.api("POST", "/api/modulos", {
      token: D.token, body: { cursoId, nombre: "Duplicado", descripcion: "Mismo orden", orden: modulo.orden },
    });
    assert.equal(r.status, 409);
  });

  test("CP-MT-04 crear, listar, actualizar y publicar tema", async () => {
    const c = await srv.api("POST", `/api/modulos/${modulo.id}/temas`, {
      token: D.token, body: { nombre: "Tema QA", descripcion: "Tema de prueba", orden: 1 },
    });
    assert.equal(c.status, 201, JSON.stringify(c.data));
    tema = c.data.data;
    const lista = await srv.api("GET", `/api/modulos/${modulo.id}/temas`, { token: D.token });
    assert.ok(lista.data.data.some((t) => t.id === tema.id));
    const u = await srv.api("PUT", `/api/temas/${tema.id}`, {
      token: D.token, body: { nombre: "Tema QA (editado)", descripcion: "Editado", orden: 1 },
    });
    assert.equal(u.status, 200);
    const p = await srv.api("PATCH", `/api/temas/${tema.id}/estado`, { token: D.token, body: { estado: "PUBLICADO" } });
    assert.equal(p.status, 200);
    const db = await fila("SELECT nombre, estado, modulo_id FROM temas WHERE id = $1", [tema.id]);
    assert.deepEqual(db, { nombre: "Tema QA (editado)", estado: "PUBLICADO", modulo_id: modulo.id });
  });

  test("CP-MT-05 cambiar estado del módulo", async () => {
    for (const estado of ["PUBLICADO", "ARCHIVADO", "BORRADOR"]) {
      const r = await srv.api("PATCH", `/api/modulos/${modulo.id}/estado`, { token: D.token, body: { estado } });
      assert.equal(r.status, 200, `${estado}: ${JSON.stringify(r.data)}`);
      assert.equal((await fila("SELECT estado FROM modulos WHERE id = $1", [modulo.id])).estado, estado);
    }
  });

  test("CP-MT-06 reglas de eliminación de temas y módulos", async () => {
    // Un módulo con temas no se elimina.
    const conTemas = await srv.api("DELETE", `/api/modulos/${modulo.id}`, { token: D.token });
    assert.equal(conTemas.status, 409);
    // Un tema PUBLICADO tampoco: primero vuelve a BORRADOR.
    await srv.api("PATCH", `/api/temas/${tema.id}/estado`, { token: D.token, body: { estado: "BORRADOR" } });
    assert.equal((await srv.api("DELETE", `/api/temas/${tema.id}`, { token: D.token })).status, 200);
    assert.equal(await fila("SELECT id FROM temas WHERE id = $1", [tema.id]), undefined, "el tema ya no está en la base");
    assert.equal((await srv.api("DELETE", `/api/modulos/${modulo.id}`, { token: D.token })).status, 200);
    assert.equal(await fila("SELECT id FROM modulos WHERE id = $1", [modulo.id]), undefined, "el módulo ya no está en la base");
  });

  test("CP-MT-07 datos inválidos e ids inexistentes en módulos y temas", async () => {
    const base = { cursoId, nombre: "N", descripcion: "D", orden: ordenUnico() };
    const casos = [
      ["POST", "/api/modulos", { ...base, nombre: "" }, 400],
      ["POST", "/api/modulos", { ...base, orden: 0 }, 400],
      ["POST", "/api/modulos", { ...base, orden: "abc" }, 400],
      ["POST", "/api/modulos", { ...base, estado: "OTRO" }, 400],
      ["POST", "/api/modulos", { ...base, descripcion: "x".repeat(1001) }, 400],
      ["PUT", "/api/modulos/abc", base, 400],
      ["PATCH", "/api/temas/99999999/estado", { estado: "PUBLICADO" }, 404],
      ["DELETE", "/api/modulos/99999999", undefined, 404],
      ["GET", "/api/modulos/99999999/temas", undefined, 404],
    ];
    const errores = [];
    for (const [m, ruta, body, esperado] of casos) {
      const r = await srv.api(m, ruta, { token: D.token, body });
      if (r.status !== esperado) errores.push(`${m} ${ruta} ${JSON.stringify(body).slice(0, 60)} → ${r.status} (esperado ${esperado})`);
    }
    assert.deepEqual(errores, []);
  });

  test("CP-MT-08 el estudiante solo ve módulos y temas publicados", async () => {
    const A = await srv.sesion("ADMINISTRADOR");
    const E = await srv.sesion("ESTUDIANTE");
    const sql = await fila("SELECT id FROM cursos WHERE codigo = 'DEMO-SQL-007'");
    const m = await srv.api("POST", "/api/modulos", {
      token: A.token, body: { cursoId: sql.id, nombre: `Borrador QA ${sufijo}`, descripcion: "Oculto", orden: ordenUnico() },
    });
    assert.equal(m.status, 201);
    const visibles = async () =>
      (await srv.api("GET", `/api/mis-cursos/${sql.id}/modulos`, { token: E.token })).data.data.map((x) => x.id);
    assert.ok(!(await visibles()).includes(m.data.data.id), "el BORRADOR no se muestra");
    await srv.api("PATCH", `/api/modulos/${m.data.data.id}/estado`, { token: A.token, body: { estado: "PUBLICADO" } });
    assert.ok((await visibles()).includes(m.data.data.id), "al publicarlo aparece");
    // Limpieza: volver a BORRADOR y eliminar.
    await srv.api("PATCH", `/api/modulos/${m.data.data.id}/estado`, { token: A.token, body: { estado: "BORRADOR" } });
    await srv.api("DELETE", `/api/modulos/${m.data.data.id}`, { token: A.token });
  });
});
