
import math
import pandas as pd


REQUIRED_COLUMNS = [
    "study_minutes",
    "errors",
    "attempts",
    "repetitions",
    "navigation_count",
    "score_percentage",
]

INTEGER_COLUMNS = [
    "errors",
    "attempts",
    "repetitions",
    "navigation_count",
]


def analyze_behavior(student_data: dict) -> dict:
    """Analiza las interacciones registradas del estudiante."""

    # Validar la estructura principal.
    if not isinstance(student_data, dict):
        raise ValueError("La entrada debe ser un objeto JSON.")

    # Validar los campos obligatorios.
    for field in ("student_id", "topic"):
        if field not in student_data:
            raise ValueError(f"Falta el campo obligatorio: {field}")

    interactions = student_data.get("interactions", [])

    if not isinstance(interactions, list):
        raise ValueError("Las interacciones deben ser una lista.")

    if not interactions:
        raise ValueError(
            "El estudiante debe tener al menos una interacción."
        )

    # Validar cada interacción antes de procesarla con Pandas.
    for index, interaction in enumerate(interactions, start=1):

        if not isinstance(interaction, dict):
            raise ValueError(
                f"La interacción {index} debe ser un objeto."
            )

        for column in REQUIRED_COLUMNS:

            if column not in interaction:
                raise ValueError(
                    f"Falta el campo {column} en la interacción {index}."
                )

            value = interaction[column]

            # Rechazar booleanos como valores numéricos.
            if isinstance(value, bool):
                raise ValueError(
                    f"El campo {column} no admite valores booleanos."
                )

            # Validar que el valor pueda convertirse a número.
            try:
                numeric_value = float(value)
            except (ValueError, TypeError, OverflowError):
                raise ValueError(
                    f"El campo {column} debe ser numérico."
                )

            # Rechazar NaN e Infinity.
            if not math.isfinite(numeric_value):
                raise ValueError(
                    f"El campo {column} debe ser un número finito."
                )

            # Validar los campos que requieren números enteros.
            if column in INTEGER_COLUMNS:
                if not numeric_value.is_integer():
                    raise ValueError(
                        f"El campo {column} debe ser un número entero."
                    )

    df = pd.DataFrame(interactions)

    df[REQUIRED_COLUMNS] = df[REQUIRED_COLUMNS].apply(
        pd.to_numeric, errors="coerce"
    )

    if df[REQUIRED_COLUMNS].isnull().any().any():
        raise ValueError("Los datos deben ser numéricos y válidos.")

    # Validar los rangos permitidos.
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
