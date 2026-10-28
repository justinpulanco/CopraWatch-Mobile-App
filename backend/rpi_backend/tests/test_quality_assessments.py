import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from database import RPiDatabase


class QualityAssessmentTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.database = RPiDatabase(str(Path(self.temp_dir.name) / "quality.db"))

    def tearDown(self):
        self.database = None
        self.temp_dir.cleanup()

    def _execute(self, sql, params):
        connection = self.database.get_connection()
        try:
            connection.execute(sql, params)
            connection.commit()
        finally:
            connection.close()

    def _insert_batch(self, batch_id):
        self._execute(
            "INSERT INTO active_batch (batch_id, batch_name, start_time) VALUES (?, ?, ?)",
            (batch_id, batch_id, "2026-01-01T00:00:00"),
        )

    def _insert_assessment(self, batch_id, image_path, timestamp):
        self._execute(
            """
            INSERT INTO quality_assessments
                (batch_id, image_path, classification, confidence, timestamp)
            VALUES (?, ?, ?, ?, ?)
            """,
            (batch_id, image_path, "Optimally-dried", 0.9, timestamp),
        )

    def test_latest_assessment_orders_by_timestamp_then_id(self):
        self._insert_batch("batch-1")
        self._insert_assessment("batch-1", "older.jpg", "2026-01-01T00:00:00")
        self._insert_assessment("batch-1", "newer-first.jpg", "2026-01-02T00:00:00")
        self._insert_assessment("batch-1", "newer-second.jpg", "2026-01-02T00:00:00")

        result = self.database.get_latest_quality_assessment()

        self.assertEqual(result["image_path"], "newer-second.jpg")

    def test_history_is_batch_scoped_and_newest_first(self):
        self._insert_batch("batch-1")
        self._insert_batch("batch-2")
        self._insert_assessment("batch-1", "older.jpg", "2026-01-01T00:00:00")
        self._insert_assessment("batch-1", "newer.jpg", "2026-01-02T00:00:00")
        self._insert_assessment("batch-2", "other-batch.jpg", "2026-01-03T00:00:00")

        results = self.database.get_quality_assessments_for_batch("batch-1")

        self.assertEqual([row["image_path"] for row in results], ["newer.jpg", "older.jpg"])
        self.assertTrue(all(row["batch_id"] == "batch-1" for row in results))


if __name__ == "__main__":
    unittest.main()
