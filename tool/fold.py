"""Diacritic+case folding for forgiving search matching.

Used by export_bible_db.py to populate verses.text_folded in bible.db, and
mirrored exactly by lib/core/text/fold.dart so a user's typed search query
folds the same way the stored text did. fold_test_vectors.json is the
shared source of truth both sides are tested against (test_fold.py here,
test/fold_test.dart on the Dart side) -- change the folding rules, update
that file, and both tests catch any disagreement.
"""

_FOLD_MAP = {
    "â": "a", "Â": "a",
    "ê": "e", "Ê": "e",
    "î": "i", "Î": "i",
    "û": "u", "Û": "u",
    "ṭ": "t", "Ṭ": "t",
}


def fold_for_search(text: str) -> str:
    return "".join(_FOLD_MAP.get(ch, ch) for ch in text).lower()
