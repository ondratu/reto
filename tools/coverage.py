#!/usr/bin/env python3
"""Run the unit tests with coverage and print line coverage of src/*.vala.

Only needs gcov. Usage: tools/coverage.py [build-dir]
"""

import json
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src")


def run(*cmd, quiet=True):
    out = subprocess.DEVNULL if quiet else None
    subprocess.run(cmd, check=True, stdout=out)


def is_source(path):
    return path.startswith(SRC + os.sep) and path.endswith(".vala")


def gcov_lines(build_dir):
    """Merge per-line execution counts of all objects, keyed by file."""
    lines = {}
    with tempfile.TemporaryDirectory() as cwd:
        for base, _, names in os.walk(build_dir):
            for name in names:
                if not name.endswith(".gcno"):
                    continue
                gcno = os.path.join(base, name)
                out = subprocess.run(
                    ["gcov", "--json-format", "--stdout", gcno],
                    cwd=cwd, check=True, capture_output=True, text=True,
                ).stdout
                for doc in out.splitlines():
                    data = json.loads(doc)
                    for entry in data["files"]:
                        path = os.path.normpath(os.path.join(
                            data["current_working_directory"], entry["file"]
                        ))
                        if not is_source(path):
                            continue
                        merged = lines.setdefault(path, {})
                        for line in entry["lines"]:
                            number = line["line_number"]
                            count = merged.get(number, 0)
                            merged[number] = count + line["count"]
    return lines


def report(hit, total, label):
    percent = 100 * hit / total
    text = f"{percent:6.1f}%"
    if sys.stdout.isatty():
        color = 32 if percent >= 90 else 33 if percent >= 50 else 31
        text = f"\033[{color}m{text}\033[0m"
    return f"{text}  {hit:4}/{total:<4} {label}"


def main():
    default_dir = os.path.join(ROOT, "build-coverage")
    build_dir = os.path.abspath(
        sys.argv[1] if len(sys.argv) > 1 else default_dir
    )
    if not os.path.isdir(build_dir):
        run("meson", "setup", build_dir, ROOT, "-Db_coverage=true")
    run("meson", "compile", "-C", build_dir)
    # Counters accumulate across runs; start from zero.
    for base, _, names in os.walk(build_dir):
        for name in names:
            if name.endswith(".gcda"):
                os.remove(os.path.join(base, name))
    run("meson", "test", "-C", build_dir, "--print-errorlogs", quiet=False)
    print()

    total = covered = 0
    for path, counts in sorted(gcov_lines(build_dir).items()):
        hit = sum(1 for count in counts.values() if count > 0)
        total += len(counts)
        covered += hit
        print(report(hit, len(counts), os.path.relpath(path, ROOT)))
    if total:
        print(report(covered, total, "total"))


if __name__ == "__main__":
    main()
