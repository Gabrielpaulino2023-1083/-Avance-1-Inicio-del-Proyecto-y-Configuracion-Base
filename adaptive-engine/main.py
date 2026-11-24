
import json
import sys
from pathlib import Path

from engine import process_student


BASE_DIR = Path(__file__).resolve().parent
DATA_FILE = BASE_DIR / "data" / "estudiante_prueba.json"


def reject_invalid_constant(value):
    """Rechaza constantes no permitidas en JSON."""
    raise ValueError(f"Valor JSON no permitido: {value}")


def main():
    try:
        if "--stdin" in sys.argv:
            student_data = json.load(
                sys.stdin,
                parse_constant=reject_invalid_constant
            )
        else:
            with DATA_FILE.open("r", encoding="utf-8") as file:
                student_data = json.load(
                    file,
                    parse_constant=reject_invalid_constant
                )

        result = process_student(student_data)

        if "--stdin" in sys.argv:
            print(json.dumps(
                result,
                ensure_ascii=False,
                allow_nan=False
            ))
        else:
            print("\n=== PERFIL DEL ESTUDIANTE ===")
            print(json.dumps(
                result["profile"],
                indent=4,
                ensure_ascii=False,
                allow_nan=False
            ))

            print("\n=== RECOMENDACIÓN ADAPTATIVA ===")
            print(json.dumps(
                result["recommendation"],
                indent=4,
                ensure_ascii=False,
                allow_nan=False
            ))

    except (ValueError, KeyError, TypeError,
            OverflowError, OSError) as error:

        print(json.dumps({
            "error": str(error)
        }, ensure_ascii=False), file=sys.stderr)

        sys.exit(1)


if __name__ == "__main__":
    main()
