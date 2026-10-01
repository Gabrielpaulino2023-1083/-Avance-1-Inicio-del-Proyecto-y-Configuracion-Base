import pandas as pd


def analyze_behavior(student_data: dict) -> dict:
    """Analiza las interacciones registradas del estudiante."""

    interactions = student_data.get("interactions", [])

    if not interactions:
        raise ValueError(
            "El estudiante debe tener al menos una interacción."
        )

    df = pd.DataFrame(interactions)

    required_columns = [
        "study_minutes",
        "errors",
        "attempts",
        "repetitions",
        "navigation_count",
        "score_percentage",
    ]

    missing = [
        column for column in required_columns
        if column not in df.columns
    ]

    if missing:
        raise ValueError(
            f"Faltan campos obligatorios: {', '.join(missing)}"
        )

    df[required_columns] = df[required_columns].apply(
        pd.to_numeric, errors="coerce"
    )

    if df[required_columns].isnull().any().any():
        raise ValueError("Los datos deben ser numéricos y válidos.")

    if (
        (df["study_minutes"] < 0).any()
        or (df["errors"] < 0).any()
        or (df["attempts"] < 1).any()
        or (df["repetitions"] < 0).any()
        or (df["navigation_count"] < 0).any()
        or (~df["score_percentage"].between(0, 100)).any()
    ):
        raise ValueError("Hay valores fuera de los rangos permitidos.")

    return {
        "student_id": student_data["student_id"],
        "topic": student_data["topic"],
        "average_score": round(
            df["score_percentage"].mean(), 2
        ),
        "total_errors": int(df["errors"].sum()),
        "average_attempts": round(
            df["attempts"].mean(), 2
        ),
        "total_repetitions": int(df["repetitions"].sum()),
        "average_study_minutes": round(
            df["study_minutes"].mean(), 2
        ),
        "total_interactions": len(df),
    }