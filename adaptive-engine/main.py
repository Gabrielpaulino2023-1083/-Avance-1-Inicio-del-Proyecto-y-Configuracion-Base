
import json
import sys
from pathlib import Path

from analysis.analyzer import analyze_behavior
from rules.adaptation_rules import generate_recommendation

BASE_DIR = Path(__file__).resolve().parent
DATA_FILE = BASE_DIR / "data" / "estudiante_prueba.json"


def main():
    try:
        if "--stdin" in sys.argv:
            student_data = json.load(sys.stdin)
        else:
            with DATA_FILE.open("r", encoding="utf-8") as file:
                student_data = json.load(file)

        profile = analyze_behavior(student_data)
        recommendation = generate_recommendation(profile)

        if "--stdin" in sys.argv:
            result = {
                "profile": profile,
                "recommendation": recommendation
            }
            print(json.dumps(result, ensure_ascii=False))
        else:
            print("\n=== PERFIL DEL ESTUDIANTE ===")
            print(json.dumps(profile, indent=4, ensure_ascii=False))

            print("\n=== RECOMENDACIÓN ADAPTATIVA ===")
            print(json.dumps(recommendation, indent=4, ensure_ascii=False))

    except (ValueError, KeyError, TypeError) as error:
        print(json.dumps({"error": str(error)}, ensure_ascii=False), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
