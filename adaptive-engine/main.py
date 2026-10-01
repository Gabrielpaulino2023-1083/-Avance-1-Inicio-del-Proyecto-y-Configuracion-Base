import json
from pathlib import Path

from analysis.analyzer import analyze_behavior
from rules.adaptation_rules import generate_recommendation


BASE_DIR = Path(__file__).resolve().parent
DATA_FILE = BASE_DIR / "data" / "estudiante_prueba.json"


def main():
    with DATA_FILE.open("r", encoding="utf-8") as file:
        student_data = json.load(file)

    profile = analyze_behavior(student_data)
    recommendation = generate_recommendation(profile)

    print("\n=== PERFIL DEL ESTUDIANTE ===")
    print(json.dumps(profile, indent=4, ensure_ascii=False))

    print("\n=== RECOMENDACIÓN ADAPTATIVA ===")
    print(json.dumps(recommendation, indent=4, ensure_ascii=False))


if __name__ == "__main__":
    main()