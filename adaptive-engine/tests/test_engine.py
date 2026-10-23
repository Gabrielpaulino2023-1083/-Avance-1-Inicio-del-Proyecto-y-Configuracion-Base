
import unittest

from engine import process_student


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


if __name__ == "__main__":
    unittest.main()
