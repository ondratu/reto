#!/usr/bin/env python3
"""CSS validator: checks brace balance and detects truncated rules."""
import re
import sys


def validate(path: str) -> list[str]:
    errors = []
    source = open(path, encoding="utf-8").read()

    # Strip comments and string literals before counting
    clean = re.sub(r"/\*.*?\*/", "", source, flags=re.DOTALL)
    clean = re.sub(r'"[^"]*"|\'[^\']*\'', "", clean)

    opens = clean.count("{")
    closes = clean.count("}")
    if opens != closes:
        errors.append(f"unbalanced braces: {opens} '{{' vs {closes} '}}'")

    # Detect rules without a closing brace (selector line immediately followed
    # by another selector or end-of-file without a matching })
    # Simple heuristic: find { not followed eventually by }
    depth = 0
    for i, ch in enumerate(clean):
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth < 0:
                line = clean[:i].count("\n") + 1
                errors.append(f"unexpected '}}' at line {line}")
                depth = 0

    if depth != 0:
        errors.append(f"unclosed rule block (depth={depth} at end of file)")

    return errors


def main() -> int:
    ok = True
    for path in sys.argv[1:]:
        errs = validate(path)
        if errs:
            for e in errs:
                print(f"{path}: {e}")
            ok = False
        else:
            print(f"{path}: OK")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
