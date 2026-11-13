#!/usr/bin/env python3
"""Package the declared ForeverUI addon without repository or local work files."""
import argparse
from pathlib import Path
import re
import zipfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path("dist"))
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    addon = root / "ForeverUI"
    toc = addon / "ForeverUI.toc"
    text = toc.read_text(encoding="utf-8")
    match = re.search(r"^## Version:\s*([A-Za-z0-9._-]+)\s*$", text, re.MULTILINE)
    if not match:
        raise SystemExit("TOC version is missing or invalid")
    declared = ["ForeverUI.toc", "LICENSE", "MediaSources.md", "Notices/ForeverHunter-LICENSE"]
    declared.extend(line.strip().replace("\\", "/") for line in text.splitlines()
                    if line.strip() and not line.lstrip().startswith("#"))
    sources = []
    for name in dict.fromkeys(declared):
        relative = Path(name)
        if relative.is_absolute() or ".." in relative.parts:
            raise SystemExit(f"Invalid package entry: {name}")
        path = addon / relative
        if path.is_symlink() or not path.is_file() or not path.resolve().is_relative_to(addon.resolve()):
            raise SystemExit(f"Missing or invalid package file: {name}")
        sources.append((name, path))
    output = args.output if args.output.is_absolute() else root / args.output
    output.mkdir(parents=True, exist_ok=True)
    archive = output / f"ForeverUI-{match.group(1)}.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as package:
        for name, path in sources:
            info = zipfile.ZipInfo(f"ForeverUI/{name}", date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            package.writestr(info, path.read_bytes())
    print(f"Built {archive.name}: {len(sources)} files")


if __name__ == "__main__":
    main()
