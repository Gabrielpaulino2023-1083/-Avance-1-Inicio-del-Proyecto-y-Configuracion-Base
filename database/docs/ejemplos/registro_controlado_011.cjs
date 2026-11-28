// Ejemplo para adaptar SOLO userModel.create despues de instalar 011.
// No reemplazar el resto del modelo. No se ha aplicado al backend.
function crearAdaptadorRegistro(pool) {
  return async function create({ nombre, apellido, email, passwordHash, rol }) {
    if (rol !== 'ESTUDIANTE') throw new Error('Este adaptador es solo para registro publico ESTUDIANTE.');
    const { rows: [u] } = await pool.query(
      'SELECT * FROM public.registrar_estudiante($1,$2,$3,$4)',
      [nombre, apellido, email, passwordHash]
    );
    return { id: u.id, nombre: u.nombre, apellido: u.apellido, email: u.email, rol: u.rol_principal };
  };
}
module.exports = { crearAdaptadorRegistro };
