# Mensaje propuesto para backend, motor y frontend

Preparé una propuesta de BD para sugerir una actividad además del tema. Agrega dificultad BAJA/MEDIA/ALTA, sin clasificar automáticamente las actividades anteriores, y una función que devuelve candidatas del mismo tema y sección, publicadas, disponibles, con intentos restantes y sin intento abierto del estudiante. Incluí un selector JS de ejemplo y un seed independiente con preguntas distintas por nivel, usando el estudiante demo existente sin cambiar sus credenciales.

La regla implementada para su revisión interpreta reduced/current/increased respecto de la actividad recién calificada; en dashboard usa la última calificada del tema e inscripción. Prefiere otra actividad, luego el nivel más cercano al objetivo, con empate hacia el nivel menor y después el ID. Si no hay referencia clasificada o candidata, conserva únicamente la recomendación del tema. No cambia las firmas 007/008 ni el motor.

Esta implementación queda pendiente de su aprobación: si les funciona, podemos integrar el contrato opcional actividadSugerida; si necesitan ajustes, los revisamos antes del merge. Backend incorporaría consulta y selector, frontend mostraría el botón sin iniciar automáticamente y motor confirmaría la interpretación relativa. La BD y el selector pasaron pruebas embebidas; Jeison confirmó también la instalación y las pruebas en base nueva y base local. Falta integrar y comprobar el recorrido HTTP completo. La guía DIFICULTAD_ACTIVIDADES_009.md contiene las reglas y los pasos.

Para el cierre conjunto, confirmemos también que los porcentajes de Progreso y la recomendación siguen la definición acordada; el ajuste parece realizado, pero queda verificarlo en la prueba final.
