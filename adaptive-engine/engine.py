from analysis.analyzer import analyze_behavior
from rules.adaptation_rules import generate_recommendation


def process_student(student_data: dict) -> dict:
    """
    Procesa los datos de comportamiento de un estudiante
    y genera una recomendación adaptativa.
    """

    profile = analyze_behavior(student_data)
    recommendation = generate_recommendation(profile)

    return {
        "profile": profile,
        "recommendation": recommendation,
    }