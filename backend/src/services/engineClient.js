
const { spawn } = require('node:child_process');
const path = require('node:path');

// Ejecuta el motor adaptativo de Python.
const runEngine = async (payload) => {
  if (!Array.isArray(payload.interactions) || payload.interactions.length === 0) {
    throw new Error('El motor necesita al menos una interacción del estudiante.');
  }

  const rootDir = path.resolve(__dirname, '../../..');

  const pythonPath = process.env.PYTHON_EXECUTABLE ||
    path.join(
      rootDir,
      '.venv',
      process.platform === 'win32' ? 'Scripts/python.exe' : 'bin/python'
    );

  const scriptPath = path.join(rootDir, 'adaptive-engine', 'main.py');

  return new Promise((resolve, reject) => {
    const python = spawn(pythonPath, [scriptPath, '--stdin'], {
      cwd: path.dirname(scriptPath)
    });

    let output = '';
    let errorOutput = '';

    python.stdout.setEncoding('utf8');
    python.stderr.setEncoding('utf8');

    python.stdout.on('data', (data) => {
      output += data;
    });

    python.stderr.on('data', (data) => {
      errorOutput += data;
    });

    python.on('error', (error) => {
      reject(new Error(`No se pudo ejecutar Python: ${error.message}`));
    });

    python.on('close', (code) => {
      if (code !== 0) {
        reject(new Error(`Error del motor Python: ${errorOutput.trim()}`));
        return;
      }

      try {
        const result = JSON.parse(output);
        const recommendation = result.recommendation;

        if (!recommendation || typeof recommendation !== 'object') {
          throw new Error('Python no devolvió una recomendación válida.');
        }

        resolve({
          student_id: recommendation.student_id,
          topic: recommendation.topic,
          action: recommendation.action,
          difficulty: recommendation.difficulty,
          recommendation: recommendation.recommendation
        });
      } catch (error) {
        reject(new Error(`Respuesta inválida del motor: ${error.message}`));
      }
    });

    python.stdin.on('error', () => {
      // El proceso Python puede cerrar stdin si falla antes de leer los datos.
    });

    python.stdin.end(JSON.stringify(payload));
  });
};

module.exports = { runEngine };
