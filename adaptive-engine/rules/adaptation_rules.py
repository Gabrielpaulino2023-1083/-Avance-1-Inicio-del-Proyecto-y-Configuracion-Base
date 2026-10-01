def generate_recommendation(profile: dict) -> dict:
    """Genera una recomendación según el desempeño del estudiante."""

    score = profile["average_score"]
    errors = profile["total_errors"]
    attempts = profile["average_attempts"]
    repetitions = profile["total_repetitions"]
    topic = profile["topic"]

    if score < 60 or errors >= 5:
        action = "reinforce_topic"
        difficulty = "reduced"
        message = (
            f"Se recomienda reforzar el tema {topic} "
            "con explicaciones y ejercicios guiados."
        )

    elif score >= 85 and errors <= 2 and attempts <= 2:
        action = "increase_difficulty"
        difficulty = "increased"
        message = (
            f"El estudiante muestra buen desempeño en {topic}. "
            "Se recomienda probar ejercicios más difíciles."
        )

    else:
        action = "maintain_difficulty"
        difficulty = "current"
        message = (
            f"Se recomienda mantener el nivel de {topic} "
            "y continuar evaluando el progreso."
        )

    if repetitions >= 5 and action == "reinforce_topic":
        message += (
            " Conviene ofrecer material complementario "
            "con una explicación diferente."
        )

    return {
        "student_id": profile["student_id"],
        "topic": topic,
        "action": action,
        "difficulty": difficulty,
        "reason": (
            f"Puntuación promedio: {score}%; "
            f"errores acumulados: {errors}; "
            f"intentos promedio: {attempts}."
        ),
        "recommendation": message,
    }