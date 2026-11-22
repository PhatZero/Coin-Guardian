"""Validate the build tooling before gameplay source is added."""
from pathlib import Path
from tempfile import TemporaryDirectory
import sys
import unittest
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import build


class ManifestTests(unittest.TestCase):
    def setUp(self):
        self.tmp = TemporaryDirectory()
        self.addon = Path(self.tmp.name)
        (self.addon / "CoinGuardian.toc").write_text(
            "## Interface: 16001\n## Title: Coin Guardian\n## Version: 1.0b1\n\nCore.lua\n", encoding="utf-8"
        )
        (self.addon / "Core.lua").write_text("-- Fixture\n", encoding="utf-8")

    def tearDown(self):
        self.tmp.cleanup()

    def test_valid_manifest(self):
        version, files = build.validate_manifest(self.addon)
        self.assertEqual(version, "1.0b1")
        self.assertIn(Path("Core.lua"), files)

    def test_missing_source_rejected(self):
        (self.addon / "Core.lua").unlink()
        with self.assertRaisesRegex(ValueError, "Missing TOC file"):
            build.validate_manifest(self.addon)

    def test_traversal_rejected(self):
        (self.addon / "CoinGuardian.toc").write_text(
            "## Interface: 16001\n## Version: 1.0b1\n../outside.lua\n", encoding="utf-8"
        )
        with self.assertRaisesRegex(ValueError, "Unsafe manifest entry"):
            build.validate_manifest(self.addon)

    def test_manifest_version_validation(self):
        toc = self.addon / "CoinGuardian.toc"
        toc.write_text(toc.read_text(encoding="utf-8").replace("1.0b1", "bad"), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Unrecognized version"):
            build.validate_manifest(self.addon)

    def test_repository_placeholder_excluded(self):
        (self.addon / ".gitkeep").write_text("placeholder", encoding="utf-8")
        version, files = build.validate_manifest(self.addon)
        self.assertEqual(version, "1.0b1")
        self.assertNotIn(Path(".gitkeep"), files)

    def test_local_alpha_version(self):
        toc = self.addon / "CoinGuardian.toc"
        toc.write_text(toc.read_text(encoding="utf-8").replace("1.0b1", "0.1.0-alpha"), encoding="utf-8")
        version, _ = build.validate_manifest(self.addon)
        self.assertEqual(version, "0.1.0-alpha")

    def test_repository_placeholder_excluded(self):
        (self.addon / ".gitkeep").write_text("placeholder", encoding="utf-8")
        _, files = build.validate_manifest(self.addon)
        self.assertNotIn(Path(".gitkeep"), files)

    def test_package_layout(self):
        with TemporaryDirectory() as directory:
            output = build.build(self.addon, Path(directory))
            with zipfile.ZipFile(output) as archive:
                self.assertIn("CoinGuardian/CoinGuardian.toc", archive.namelist())
                self.assertIn("CoinGuardian/Core.lua", archive.namelist())


if __name__ == "__main__":
    unittest.main()
