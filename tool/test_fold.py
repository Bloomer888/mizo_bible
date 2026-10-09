#!/usr/bin/env python3
"""Checks fold.py against fold_test_vectors.json (shared with fold_test.dart)."""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from fold import fold_for_search

VECTORS_PATH = Path(__file__).parent / "fold_test_vectors.json"


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    vectors = json.loads(VECTORS_PATH.read_text(encoding="utf-8"))

    failures = []
    for v in vectors:
        got = fold_for_search(v["input"])
        if got != v["folded"]:
            failures.append((v["input"], v["folded"], got))

    print(f"{len(vectors) - len(failures)}/{len(vectors)} vectors passed")
    for input_, expected, got in failures:
        print(f"  FAIL: fold_for_search({input_!r}) = {got!r}, expected {expected!r}")

    if failures:
        sys.exit(1)


if __name__ == "__main__":
    main()
