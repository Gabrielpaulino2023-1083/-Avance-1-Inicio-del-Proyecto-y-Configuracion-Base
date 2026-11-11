// Pruebas unitarias del backend: DTOs, middlewares, manejo de errores y OpenAPI.
// No necesitan base de datos: se cargan los módulos sueltos de backend/src.
//
// Ejecutar: node --test tests/unit/backend
import { test, describe } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { BACKEND_DIR, requireFromBackend, configureBackendEnv } from "../../config.mjs";

configureBackendEnv();
const src = (p) => requireFromBackend(path.join(BACKEND_DIR, "src", p));

const { registerDto, loginDto, toUserResponse } = src("dtos/auth.dto.js");
const validate = src("middlewares/validate.js");
const { verifyToken, requireRole, requirePermission } = src("middlewares/authMiddleware.js");
const { errorHandler, notFound } = src("middlewares/errorHandler.js");
const AppError = src("errors/AppError.js");
const { ROLES, ROLE_VALUES } = src("config/roles.js");
const { PERMISSIONS } = src("config/permissions.js");
const config = src("config/config.js");
const jwt = requireFromBackend("jsonwebtoken");

// Respuesta falsa de Express para observar status y json.
function fakeRes() {
  return {
    statusCode: 200,
    body: undefined,
    status(code) { this.statusCode = code; return this; },
    json(payload) { this.body = payload; return this; },
  };
}

// Ejecuta un middleware y devuelve { error, nextCalled }.
function run(middleware, req) {
  let nextCalled = false;
  try {
    middleware(req, fakeRes(), () => { nextCalled = true; });
    return { error: null, nextCalled };
  } catch (error) {
    return { error, nextCalled };
  }
}

const valid = { nombre: "Ana", apellido: "Pérez", email: "ana@example.com", password: "Segura123" };

describe("CP-BE-01 registerDto acepta y rechaza según las reglas", () => {
  test("CP-BE-01 acepta datos válidos y aplica trim", () => {
    const r = registerDto.safeParse({ ...valid, nombre: "  Ana  ", email: "  ana@example.com " });
    assert.equal(r.success, true);
    assert.equal(r.data.nombre, "Ana");
    assert.equal(r.data.email, "ana@example.com");
  });

  const invalids = [
    ["email mal formado", { email: "ana@" }, "email"],
    ["contraseña de 7 caracteres", { password: "1234567" }, "password"],
    ["contraseña de 73 caracteres", { password: "a".repeat(73) }, "password"],
    ["nombre vacío", { nombre: "   " }, "nombre"],
    ["apellido de 51 caracteres", { apellido: "x".repeat(51) }, "apellido"],
    ["nombre numérico", { nombre: 123 }, "nombre"],
  ];
  for (const [label, override, campo] of invalids) {
    test(`CP-BE-01 rechaza ${label}`, () => {
      const r = registerDto.safeParse({ ...valid, ...override });
      assert.equal(r.success, false);
      assert.ok(r.error.issues.some((i) => i.path[0] === campo), `debe señalar ${campo}`);
    });
  }

  test("CP-BE-01 acepta los límites exactos (8 y 72 caracteres, 50 en nombre)", () => {
    assert.equal(registerDto.safeParse({ ...valid, password: "a".repeat(8) }).success, true);
    assert.equal(registerDto.safeParse({ ...valid, password: "a".repeat(72) }).success, true);
    assert.equal(registerDto.safeParse({ ...valid, nombre: "n".repeat(50) }).success, true);
  });
});

describe("CP-BE-02 loginDto exige email y password", () => {
  for (const [label, body] of [
    ["vacíos", { email: "", password: "" }],
    ["ausentes", {}],
    ["email solo con espacios", { email: "   ", password: "x" }],
    ["password numérico", { email: "a@b.com", password: 12345678 }],
  ]) {
    test(`CP-BE-02 rechaza campos ${label}`, () => {
      assert.equal(loginDto.safeParse(body).success, false);
    });
  }
  test("CP-BE-02 acepta credenciales con formato correcto", () => {
    assert.equal(loginDto.safeParse({ email: "a@b.com", password: "x" }).success, true);
  });
});

test("CP-BE-03 toUserResponse nunca expone campos internos", () => {
  const out = toUserResponse({
    id: 7, nombre: "A", apellido: "B", email: "a@b.com", rol: "ESTUDIANTE",
    passwordHash: "$2a$10$secreto", activo: true, password_hash: "x",
  });
  assert.deepEqual(Object.keys(out).sort(), ["apellido", "email", "id", "nombre", "rol"]);
});

describe("CP-BE-04 middleware validate", () => {
  test("CP-BE-04 cuerpo inválido → AppError 400 con details {campo, mensaje}", () => {
    const { error, nextCalled } = run(validate(registerDto), { body: { ...valid, email: "x" } });
    assert.equal(nextCalled, false);
    assert.ok(error instanceof AppError);
    assert.equal(error.status, 400);
    assert.equal(error.message, "Datos inválidos");
    assert.deepEqual(Object.keys(error.details[0]).sort(), ["campo", "mensaje"]);
    assert.equal(error.details[0].campo, "email");
  });
  test("CP-BE-04 cuerpo válido → next() y req.body limpio", () => {
    const req = { body: { ...valid, apellido: " Pérez ", extra: "se descarta" } };
    const { error, nextCalled } = run(validate(registerDto), req);
    assert.equal(error, null);
    assert.equal(nextCalled, true);
    assert.equal(req.body.apellido, "Pérez");
    assert.equal(req.body.extra, undefined);
  });
});

describe("CP-BE-05 middleware verifyToken", () => {
  const sign = (payload, opts = {}, secret = config.jwtSecret) =>
    jwt.sign(payload, secret, { expiresIn: "1h", ...opts });

  const cases = [
    ["sin cabecera", undefined],
    ["esquema Basic", "Basic abc"],
    ["Bearer sin token", "Bearer "],
    ["token basura", "Bearer no.es.un.jwt"],
    ["firmado con otro secreto", `Bearer ${sign({ id: 1, rol: "ESTUDIANTE" }, {}, "otro-secreto")}`],
    ["expirado", `Bearer ${sign({ id: 1, rol: "ESTUDIANTE" }, { expiresIn: -10 })}`],
  ];
  for (const [label, header] of cases) {
    test(`CP-BE-05 rechaza ${label} con 401`, () => {
      const { error, nextCalled } = run(verifyToken, { headers: { authorization: header } });
      assert.equal(nextCalled, false);
      assert.equal(error?.status, 401);
    });
  }
  test("CP-BE-05 token válido → req.user con id y rol", () => {
    const req = { headers: { authorization: `Bearer ${sign({ id: 42, rol: "DOCENTE" })}` } };
    const { error, nextCalled } = run(verifyToken, req);
    assert.equal(error, null);
    assert.equal(nextCalled, true);
    assert.equal(req.user.id, 42);
    assert.equal(req.user.rol, "DOCENTE");
  });
});

describe("CP-BE-06 requireRole y requirePermission", () => {
  test("CP-BE-06 requireRole permite el rol indicado y bloquea los demás", () => {
    const mw = requireRole(ROLES.DOCENTE, ROLES.ADMINISTRADOR);
    assert.equal(run(mw, { user: { rol: "DOCENTE" } }).nextCalled, true);
    assert.equal(run(mw, { user: { rol: "ESTUDIANTE" } }).error.status, 403);
    assert.equal(run(mw, {}).error.status, 403);
  });
  test("CP-BE-06 cada permiso respeta config/permissions.js para los 3 roles", () => {
    for (const [permission, allowed] of Object.entries(PERMISSIONS)) {
      for (const rol of ROLE_VALUES) {
        const r = run(requirePermission(permission), { user: { rol } });
        if (allowed.includes(rol)) assert.equal(r.nextCalled, true, `${rol} debe tener ${permission}`);
        else assert.equal(r.error?.status, 403, `${rol} NO debe tener ${permission}`);
      }
    }
  });
  test("CP-BE-06 un permiso no definido produce un error de programación", () => {
    const r = run(requirePermission("no:existe"), { user: { rol: "ADMINISTRADOR" } });
    assert.match(r.error.message, /Permiso no definido/);
  });
});

describe("CP-BE-07 errorHandler traduce cada tipo de error", () => {
  const handle = (err) => {
    const res = fakeRes();
    const original = console.error;
    console.error = () => {}; // el 500 imprime el error; se silencia en la prueba
    try { errorHandler(err, {}, res, () => {}); } finally { console.error = original; }
    return res;
  };
  test("CP-BE-07 AppError conserva su status, mensaje y details", () => {
    const res = handle(new AppError(409, "Duplicado", [{ campo: "email", mensaje: "x" }]));
    assert.equal(res.statusCode, 409);
    assert.deepEqual(res.body, { success: false, message: "Duplicado", details: [{ campo: "email", mensaje: "x" }] });
  });
  test("CP-BE-07 JSON inválido → 400 'JSON inválido'", () => {
    // Forma REAL del error que produce express.json() (body-parser): trae status 400.
    const parseError = Object.assign(new SyntaxError("Unexpected end of JSON input"), {
      type: "entity.parse.failed", status: 400, statusCode: 400, expose: true,
    });
    const res = handle(parseError);
    assert.equal(res.statusCode, 400);
    assert.equal(res.body.message, "JSON inválido");
  });
  test("CP-BE-07 violación de unicidad de PostgreSQL (23505) → 409", () => {
    assert.equal(handle({ code: "23505" }).statusCode, 409);
  });
  test("CP-BE-07 error inesperado → 500 sin filtrar el detalle interno", () => {
    const res = handle(new Error("password_hash column leaked"));
    assert.equal(res.statusCode, 500);
    assert.ok(!JSON.stringify(res.body).includes("password_hash"));
  });
  test("CP-BE-07 notFound → 404 JSON", () => {
    const res = fakeRes();
    notFound({}, res);
    assert.equal(res.statusCode, 404);
    assert.equal(res.body.success, false);
  });
});

test("CP-BE-08 OpenAPI documenta exactamente las rutas implementadas", () => {
  const openApiSpec = src("config/swagger.js");
  const documented = new Set();
  for (const [p, methods] of Object.entries(openApiSpec.paths)) {
    for (const m of Object.keys(methods)) documented.add(`${m.toUpperCase()} ${p}`);
  }

  // Rutas reales: se leen los routers montados en app.js.
  const appSrc = fs.readFileSync(path.join(BACKEND_DIR, "src/app.js"), "utf8");
  const implemented = new Set();
  for (const [, prefix, file] of appSrc.matchAll(/app\.use\('([^']+)',\s*(\w+)\)/g)) {
    const routerPath = path.join(BACKEND_DIR, "src/routes", `${file}.js`);
    if (!fs.existsSync(routerPath)) continue;
    const routerSrc = fs.readFileSync(routerPath, "utf8");
    for (const [, method, sub] of routerSrc.matchAll(/router\.(get|post|put|patch|delete)\('([^']+)'/g)) {
      implemented.add(`${method.toUpperCase()} ${prefix}${sub === "/" ? "" : sub}`);
    }
  }
  assert.deepEqual([...documented].sort(), [...implemented].sort());
  assert.deepEqual(openApiSpec.components.schemas.User.properties.rol.enum, [...ROLE_VALUES]);
});
