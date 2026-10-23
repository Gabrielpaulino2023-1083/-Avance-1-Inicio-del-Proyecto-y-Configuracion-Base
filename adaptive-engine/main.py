import json
import sys
from pathlib import Path

from engine import process_student


BASE_DIR = Path(__file__).resolve().parent
DATA_FILE = BASE_DIR / "data" / "estudiante_prueba.json"


def main():
    try:
        if "--stdin" in sys.argv:
            student_data = json.load(sys.stdin)
        else:
            with DATA_FILE.open("r", encoding="utf-8") as file:
                student_data = json.load(file)

        result = process_student(student_data)

        if "--stdin" in sys.argv:
            print(json.dumps(result, ensure_ascii=False))
        else:
            print("\n=== PERFIL DEL ESTUDIANTE ===")
            print(json.dumps(
                result["profile"],
                indent=4,
                ensure_ascii=False
            ))

            print("\n=== RECOMENDACIÓN ADAPTATIVA ===")
            print(json.dumps(
                result["recommendation"],
                indent=4,
                ensure_ascii=False
            ))

    except (ValueError, KeyError, TypeError, json.JSONDecodeError) as error:
        print(json.dumps({
            "error": str(error)
        }, ensure_ascii=False), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()