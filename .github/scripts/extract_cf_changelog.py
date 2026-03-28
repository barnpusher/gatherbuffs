from __future__ import annotations

import argparse
import pathlib
import re
import sys


HEADING_RE = re.compile(r"^##\s+(.+?)\s*$")


def normalize_version(raw: str | None) -> str | None:
    if not raw:
        return None
    value = raw.strip()
    if value.lower().startswith("refs/tags/"):
        value = value.split("/", 2)[-1]
    if value.startswith("v") and len(value) > 1:
        value = value[1:]
    return value


def split_sections(lines: list[str]) -> list[tuple[str, list[str]]]:
    sections: list[tuple[str, list[str]]] = []
    current_title: str | None = None
    current_lines: list[str] = []

    for line in lines:
        match = HEADING_RE.match(line)
        if match:
            if current_title is not None:
                sections.append((current_title, current_lines))
            current_title = match.group(1).strip()
            current_lines = []
            continue
        if current_title is not None:
            current_lines.append(line)

    if current_title is not None:
        sections.append((current_title, current_lines))

    return sections


def render_section(title: str, body_lines: list[str]) -> str:
    body = "\n".join(body_lines).strip()
    if not body:
        body = "- No changelog notes provided."
    return f"## {title}\n\n{body}\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract a single CurseForge release changelog section from CHANGELOG.md.")
    parser.add_argument("--source", default="CHANGELOG.md")
    parser.add_argument("--output", default=".cf-release-changelog.md")
    parser.add_argument("--version", default=None, help="Version heading to extract, e.g. 0.99.16 or v0.99.16.")
    parser.add_argument("--default-section", default="Unreleased")
    args = parser.parse_args()

    source_path = pathlib.Path(args.source)
    output_path = pathlib.Path(args.output)

    if not source_path.is_file():
        print(f"Missing changelog source: {source_path}", file=sys.stderr)
        return 1

    source_text = source_path.read_text(encoding="utf-8")
    sections = split_sections(source_text.splitlines())
    if not sections:
        print(f"No level-2 sections found in {source_path}", file=sys.stderr)
        return 1

    version = normalize_version(args.version)
    default_section = args.default_section.strip()

    selected_title: str | None = None
    selected_lines: list[str] | None = None

    if version:
        for title, body_lines in sections:
            if title == version:
                selected_title = title
                selected_lines = body_lines
                break
        if selected_title is None:
            print(f"Version section '## {version}' not found in {source_path}", file=sys.stderr)
            return 1
    else:
        for title, body_lines in sections:
            if title == default_section:
                selected_title = title
                selected_lines = body_lines
                break
        if selected_title is None:
            selected_title, selected_lines = sections[0]

    output_path.write_text(render_section(selected_title, selected_lines or []), encoding="utf-8")
    print(f"Wrote {output_path} from section '## {selected_title}'")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
