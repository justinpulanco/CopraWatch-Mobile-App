import json
import tempfile
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from dataset_manager import DatasetManager


class DatasetManagerTests(unittest.TestCase):
    def test_save_result_copies_image_beside_metadata(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = root / "capture.jpg"
            source.write_bytes(b"captured-image-bytes")
            manager = DatasetManager(str(root / "dataset"))

            saved = manager.save_result(
                image_path=str(source),
                batch_id="batch-123",
                classification="Optimally-dried",
                confidence=0.92,
            )

            batch_dir = root / "dataset" / "batch-123"
            dataset_image = batch_dir / "capture.jpg"
            metadata_path = batch_dir / "capture.json"
            self.assertTrue(saved)
            self.assertEqual(dataset_image.read_bytes(), source.read_bytes())
            self.assertTrue(metadata_path.is_file())
            self.assertEqual(json.loads(metadata_path.read_text())["image_path"], str(dataset_image))

    def test_save_result_fails_when_captured_image_is_missing(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            manager = DatasetManager(str(Path(temp_dir) / "dataset"))

            saved = manager.save_result(
                image_path=str(Path(temp_dir) / "missing.jpg"),
                batch_id="batch-123",
                classification="Unknown",
                confidence=0,
            )

            self.assertFalse(saved)


if __name__ == "__main__":
    unittest.main()
