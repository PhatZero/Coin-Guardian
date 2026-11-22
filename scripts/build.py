#!/usr/bin/env python3
"""Validate and package Coin Guardian for WoW Forever."""
from pathlib import Path, PurePosixPath
import re
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "addon"
DIST = ROOT / "dist"
TOC_NAME = "CoinGuardian.toc"
PACKAGE_NAME = "CoinGuardian"
INTERFACE = "16001"
SUPPORTED = {".toc", ".lua", ".xml", ".tga", ".blp", ".ttf", ".otf"}
VERSION_RE = re.compile(r"(?:[0-9]+\.[0-9]+\.[0-9]+|[0-9]+\.[0-9]+b[1-9][0-9]*)\Z")


def manifest_field(contents: str, name: str) -> str:
    matches = re.findall(rf"^## {re.escape(name)}: (.+?)\s*$", contents, re.M)
    if len(matches) != 1:
        raise ValueError(f"Expected exactly one manifest {name} field")
    return matches[0].strip()


def validate_manifest(addon: Path = ADDON):
    toc = addon / TOC_NAME
    if not toc.is_file():
        raise FileNotFoundError(f"No game addon yet: addon/{TOC_NAME} is missing")
    contents = toc.read_text(encoding="utf-8-sig")
    if manifest_field(contents, "Interface") != INTERFACE:
        raise ValueError(f"Expected WoW Forever interface {INTERFACE}; check the client version")
    version = manifest_field(contents, "Version")
    if not VERSION_RE.fullmatch(version):
        raise ValueError(f"Unrecognized version: {version!r}")
    entries = []
    for raw in contents.splitlines():
        entry = raw.strip()
        if not entry or entry.startswith("#"):
            continue
        entry = entry.replace("\\", "/")
        path = PurePosixPath(entry)
        if not path.parts or path.is_absolute() or ".." in path.parts or ":" in entry:
            raise ValueError(f"Unsafe manifest entry: {raw!r}")
        if path.suffix.lower() not in {".lua", ".xml"}:
            raise ValueError(f"Unsupported manifest entry: {raw!r}")
        source = addon.joinpath(*path.parts)
        if not source.is_file() or source.is_symlink():
            raise ValueError(f"Missing TOC file: {raw!r}")
        entries.append(path.as_posix())
    if not entries or len(entries) != len(set(entries)) or not any(x.endswith(".lua") for x in entries):
        raise ValueError("TOC must list unique source files and at least one Lua file")
    files = []
    for source in sorted(addon.rglob("*")):
        if source.is_symlink():
            raise ValueError(f"Symlinks are not allowed in addon package: {source}")
        if source.is_file():
            if source.name == ".gitkeep":
                continue  # Repository placeholder, not part of the game addon.
            if source.suffix.lower() not in SUPPORTED:
                raise ValueError(f"Unsupported addon file: {source}")
            files.append(source.relative_to(addon))
    return version, files


def build(addon: Path = ADDON, dist: Path = DIST) -> Path:
    version, files = validate_manifest(addon)
    dist.mkdir(parents=True, exist_ok=True)
    archive_path = dist / f"{PACKAGE_NAME}-Forever-{version}.zip"
    with zipfile.ZipFile(archive_path, "w", zipfile.ZIP_DEFLATED) as archive:
        for relative in files:
            archive.write(addon / relative, (PurePosixPath(PACKAGE_NAME) / relative.as_posix()).as_posix())
    with zipfile.ZipFile(archive_path) as archive:
        if archive.testzip() is not None or f"{PACKAGE_NAME}/{TOC_NAME}" not in archive.namelist():
            raise ValueError("Packaged ZIP integrity validation failed")
    return archive_path


if __name__ == "__main__":
    try:
        print("Built:", build())
    except (ValueError, FileNotFoundError) as exc:
        sys.exit(str(exc))
