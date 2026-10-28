"""Batch integration for the Raspberry Pi capture workflow."""

import sqlite3
from contextlib import contextmanager
from datetime import datetime
from typing import Any, Dict, Iterator, Optional


class BatchService:
    """Reads and updates the active batch in the backend SQLite database."""

    def __init__(self, db_path: str = "copra_data.db"):
        self.db_path = db_path

    @contextmanager
    def _connection(self) -> Iterator[sqlite3.Connection]:
        connection = sqlite3.connect(self.db_path)
        try:
            yield connection
            connection.commit()
        finally:
            connection.close()

    def get_active_batch(self) -> Optional[Dict[str, Any]]:
        with self._connection() as connection:
            row = connection.execute(
                """
                SELECT batch_id, batch_name, start_time, status
                FROM active_batch
                WHERE status = 'active'
                ORDER BY start_time DESC
                LIMIT 1
                """
            ).fetchone()

        if row is None:
            return None

        return {
            "batch_id": row[0],
            "batch_name": row[1],
            "start_time": row[2],
            "status": row[3],
        }

    def add_quality_assessment(
        self,
        batch_id: str,
        image_path: str,
        classification: str,
        confidence: float,
        timestamp: Optional[str] = None,
    ) -> bool:
        """Attach the latest automated quality result to its active batch."""
        with self._connection() as connection:
            cursor = connection.execute(
                """
                UPDATE active_batch
                SET quality_result = ?, confidence = ?
                WHERE batch_id = ? AND status = 'active'
                """,
                (classification, confidence, batch_id),
            )
            if cursor.rowcount != 1:
                return False

            connection.execute(
                """
                INSERT INTO quality_assessments
                    (batch_id, image_path, classification, confidence, timestamp)
                VALUES (?, ?, ?, ?, ?)
                """,
                (
                    batch_id,
                    image_path,
                    classification,
                    confidence,
                    timestamp or datetime.now().isoformat(),
                ),
            )
            connection.execute(
                """
                INSERT INTO system_logs (event_type, message, timestamp)
                VALUES (?, ?, ?)
                """,
                (
                    "QUALITY_ASSESSMENT",
                    f"Batch {batch_id}: {classification} ({confidence:.3f}) from {image_path}",
                    timestamp or datetime.now().isoformat(),
                ),
            )
            return True
