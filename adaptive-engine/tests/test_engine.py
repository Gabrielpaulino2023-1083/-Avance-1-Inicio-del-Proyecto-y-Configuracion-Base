
import json
import subprocess
import sys
import unittest
from pathlib import Path

from engine import process_student


BASE_DIR = Path(__file__).resolve().parents[1]


class TestAdaptiveEngine(unittest.TestCase):

    def create_student(self, student_id=1, score=75, errors=2,
                       attempts=2, repetitions=1):
        return {
            "student_id": student_id,
            "topic": "Python",
            "interactions": [
                {
                    "study_minutes": 20,
                    "errors": errors,
                    "attempts": attempts,
                    "repetitions": repetitions,
                    "navigation_count": 5,
                    "score_percentage": score
                }
            ]
        }

    # ==========================================
    # PRUEBAS ORIGINALES
    # ==========================================

    def test_low_performance(self):
        student = self.create_student(score=45, errors=6)
        result = process_student(student)

        self.assertEqual(
            result["recommendation"]["action"],
            "reinforce_topic"
        )

        self.assertEqual(
            result["recommendation"]["difficulty"],
            "reduced"
        )

    def test_medium_performance(self):
        student = self.create_student(score=75, errors=2)
        result = process_student(student)

        self.assertEqual(
            result["recommendation"]["action"],
            "maintain_difficulty"
        )

    def test_high_performance(self):
        student = self.create_student(
            score=95, errors=0, attempts=1
        )

        result = process_student(student)

        self.assertEqual(
            result["recommendation"]["action"],
            "increase_difficulty"
        )

    def test_empty_interactions(self):
        student = self.create_student()
        student["interactions"] = []

        with self.assertRaises(ValueError):
            process_student(student)

    def test_invalid_score(self):
        student = self.create_student(score=150)

        with self.assertRaises(ValueError):
            process_student(student)

    def test_missing_required_field(self):
        student = self.create_student()
        del student["interactions"][0]["navigation_count"]

        with self.assertRaises(ValueError):
            process_student(student)

    # ==========================================
    # NUEVAS PRUEBAS: INCIDENCIAS DE QA
    # ==========================================

    # INC-03: estructura incorrecta.

    def test_invalid_json_root(self):
        for value in ([], 123, "Python", None, True):
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    process_student(value)

    def test_invalid_interactions_structure(self):
        student = self.create_student()
        student["interactions"] = {"errors": 2}

        with self.assertRaises(ValueError):
            process_student(student)

    def test_invalid_interaction_item(self):
        student = self.create_student()
        student["interactions"] = [123]

        with self.assertRaises(ValueError):
            process_student(student)

    # INC-04: valores no finitos.

    def test_infinity_values(self):
        for value in (float("inf"), float("-inf")):
            student = self.create_student()
            student["interactions"][0]["study_minutes"] = value

            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    process_student(student)

    def test_nan_values(self):
        student = self.create_student()
        student["interactions"][0]["study_minutes"] = float("nan")

        with self.assertRaises(ValueError):
            process_student(student)

    # INC-05: campos principales faltantes.

    def test_missing_student_id(self):
        student = self.create_student()
        del student["student_id"]

        with self.assertRaises(ValueError):
            process_student(student)

    def test_missing_topic(self):
        student = self.create_student()
        del student["topic"]

        with self.assertRaises(ValueError):
            process_student(student)

    # INC-06: valores booleanos.

    def test_boolean_numeric_fields(self):
        fields = [
            "study_minutes",
            "errors",
            "attempts",
            "repetitions",
            "navigation_count",
            "score_percentage"
        ]

        for field in fields:
            for value in (True, False):
                student = self.create_student()
                student["interactions"][0][field] = value

                with self.subTest(field=field, value=value):
                    with self.assertRaises(ValueError):
                        process_student(student)

    # INC-07: decimales en campos enteros.

    def test_decimal_integer_fields(self):
        fields = [
            "errors",
            "attempts",
            "repetitions",
            "navigation_count"
        ]

        for field in fields:
            student = self.create_student()
            student["interactions"][0][field] = 2.5

            with self.subTest(field=field):
                with self.assertRaises(ValueError):
                    process_student(student)

    def test_valid_decimal_fields(self):
        student = self.create_student(score=75.5)
        student["interactions"][0]["study_minutes"] = 15.5

        result = process_student(student)

        self.assertEqual(
            result["profile"]["average_score"], 75.5
        )

        self.assertEqual(
            result["profile"]["average_study_minutes"], 15.5
        )

    # ==========================================
    # PRUEBAS DE COMUNICACION JSON
    # ==========================================

    def run_cli(self, payload):
        return subprocess.run(
            [sys.executable, "-X", "utf8",
             str(BASE_DIR / "main.py"), "--stdin"],
            input=payload,
            capture_output=True,
            text=True,
            encoding="utf-8",
            timeout=30
        )

    def test_cli_valid_json(self):
        student = self.create_student()
        result = self.run_cli(json.dumps(student))

        self.assertEqual(result.returncode, 0)

        response = json.loads(result.stdout)

        self.assertIn("profile", response)
        self.assertIn("recommendation", response)

    def test_cli_invalid_json_root(self):
        result = self.run_cli("[]")

        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout.strip(), "")
        self.assertIn("error", json.loads(result.stderr))
        self.assertNotIn("Traceback", result.stderr)

    def test_cli_invalid_constants(self):
        for value in ("NaN", "Infinity", "-Infinity"):
            student = self.create_student()
            student["interactions"][0]["study_minutes"] = value

            payload = json.dumps(student).replace(
                f'"{value}"', value
            )

            with self.subTest(value=value):
                result = self.run_cli(payload)

                self.assertEqual(result.returncode, 1)
                self.assertEqual(result.stdout.strip(), "")
                self.assertIn("error", json.loads(result.stderr))
                self.assertNotIn("Traceback", result.stderr)

    def test_cli_malformed_json(self):
        result = self.run_cli('{"student_id":')

        self.assertEqual(result.returncode, 1)
        self.assertIn("error", json.loads(result.stderr))
        self.assertNotIn("Traceback", result.stderr)


if __name__ == "__main__":
    unittest.main()
