// Único punto de contacto con el motor adaptativo (Python).
// Contrato:
//   entrada: { student_id, topic, interactions: [] }
//   salida:  { student_id, topic, action, difficulty, recommendation }
//
// TODO (Daniel): reemplazar el cuerpo por la llamada real a Python
// (por ejemplo con child_process.spawn: JSON por stdin, JSON por stdout).
// No cambiar la firma ni el formato de salida.
const runEngine = async (payload) => {
  return {
    student_id: payload.student_id,
    topic: payload.topic,
    action: 'reinforce_topic',
    difficulty: 'reduced',
    recommendation: `Se recomienda reforzar el tema ${payload.topic} con explicaciones y ejercicios guiados.`
  };
};

module.exports = { runEngine };