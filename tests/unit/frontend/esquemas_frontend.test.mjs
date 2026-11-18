// Pruebas unitarias de los esquemas de validación del frontend (zod).
// Node 22.18+ ejecuta TypeScript sencillo directamente (type stripping).
//
// Ejecutar: node --test tests/unit/frontend
import { test, describe } from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { FRONTEND_DIR, BACKEND_DIR, requireFromBackend, configureBackendEnv } from "../../config.mjs";

const load = (rel) => import(pathToFileURL(path.join(FRONTEND_DIR, rel)).href);
const { loginSchema } = await load("src/features/auth/loginSchema.ts");
const { registerSchema } = await load("src/features/auth/registerSchema.ts");

configureBackendEnv();
const { registerDto } = requireFromBackend(path.join(BACKEND_DIR, "src/dtos/auth.dto.js"));

const messages = (result) => result.error?.issues.map((i) => i.message) ?? [];

describe("CP-FE-01 loginSchema", () => {
  test("CP-FE-01 correo vacío → 'Ingresa tu correo.'", () => {
    const r = loginSchema.safeParse({ email: "", password: "x" });
    assert.ok(messages(r).includes("Ingresa tu correo."));
  });
  test("CP-FE-01 correo mal formado → 'Ingresa un correo válido.'", () => {
    const r = loginSchema.safeParse({ email: "correo-invalido", password: "x" });
    assert.deepEqual(messages(r), ["Ingresa un correo válido."]);
  });
  test("CP-FE-01 contraseña vacía → 'Ingresa tu contraseña.'", () => {
    const r = loginSchema.safeParse({ email: "a@b.com", password: "" });
    assert.deepEqual(messages(r), ["Ingresa tu contraseña."]);
  });
  test("CP-FE-01 datos válidos se aceptan", () => {
    assert.equal(loginSchema.safeParse({ email: "a@b.com", password: "x" }).success, true);
  });
});

const ok = {
  nombre: "Ana", apellido: "Pérez", email: "ana@example.com",
  password: "Segura123", confirmPassword: "Segura123",
};

describe("CP-FE-02 registerSchema", () => {
  const cases = [
    ["contraseñas distintas", { confirmPassword: "Otra1234" }, "confirmPassword", "Las contraseñas no coinciden."],
    ["contraseña corta", { password: "1234567", confirmPassword: "1234567" }, "password", "La contraseña debe tener al menos 8 caracteres."],
    ["contraseña de 73", { password: "a".repeat(73), confirmPassword: "a".repeat(73) }, "password", "Máximo 72 caracteres."],
    ["nombre de 51", { nombre: "n".repeat(51) }, "nombre", "Máximo 50 caracteres."],
    ["apellido vacío", { apellido: "  " }, "apellido", "Ingresa tu apellido."],
    ["confirmación vacía", { confirmPassword: "" }, "confirmPassword", "Confirma tu contraseña."],
  ];
  for (const [label, override, campo, mensaje] of cases) {
    test(`CP-FE-02 ${label} → '${mensaje}' en ${campo}`, () => {
      const r = registerSchema.safeParse({ ...ok, ...override });
      assert.equal(r.success, false);
      const issue = r.error.issues.find((i) => i.path[0] === campo);
      assert.ok(issue, `debe señalar ${campo}`);
      assert.equal(issue.message, mensaje);
    });
  }
  test("CP-FE-02 datos válidos se aceptan", () => {
    assert.equal(registerSchema.safeParse(ok).success, true);
  });
});

test("CP-FE-03 frontend y backend aceptan/rechazan los mismos registros", () => {
  const frontera = [
    {},
    { email: "  ana@example.com  " },
    { email: "ANA@EXAMPLE.COM" },
    { email: "ana@example" },
    { email: "ana.example.com" },
    { nombre: "n".repeat(50) },
    { nombre: "n".repeat(51) },
    { nombre: "" },
    { nombre: "   " },
    { apellido: "a".repeat(50) },
    { apellido: "a".repeat(51) },
    { password: "a".repeat(8) },
    { password: "a".repeat(7) },
    { password: "a".repeat(72) },
    { password: "a".repeat(73) },
    { password: "        " }, // 8 espacios
    { nombre: "José María", apellido: "Núñez-Ávila" },
  ];
  const diferencias = [];
  for (const override of frontera) {
    const data = { ...ok, ...override };
    const fe = registerSchema.safeParse({ ...data, confirmPassword: data.password }).success;
    const be = registerDto.safeParse(data).success;
    if (fe !== be) diferencias.push(`${JSON.stringify(override)} → frontend=${fe}, backend=${be}`);
  }
  assert.deepEqual(diferencias, [], `Reglas distintas:\n${diferencias.join("\n")}`);
});
