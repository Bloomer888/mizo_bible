/// Diacritic+case folding for forgiving search matching.
///
/// Must stay in exact agreement with tool/fold.py, which populates
/// verses.text_folded in bible.db -- this is what folds a user's typed
/// search query the same way. tool/fold_test_vectors.json is the shared
/// source of truth both sides are tested against (test/fold_test.dart
/// here, tool/test_fold.py on the Python side).
///
/// Currently unused by any UI: full-text search itself was removed
/// (commit b0372c0), but this folding logic -- and the matching
/// text_folded/verses_fts bits of export_bible_db.py and bible.db --
/// were deliberately kept rather than torn out, since they cost nothing
/// to leave and removing them would mean touching the Python export
/// pipeline for no benefit. Revisit together as one unit if search is
/// either brought back or finally removed for good.
library;

const Map<int, int> _foldMap = {
  0x00E2: 0x0061, // â -> a
  0x00C2: 0x0061, // Â -> a
  0x00EA: 0x0065, // ê -> e
  0x00CA: 0x0065, // Ê -> e
  0x00EE: 0x0069, // î -> i
  0x00CE: 0x0069, // Î -> i
  0x00FB: 0x0075, // û -> u
  0x00DB: 0x0075, // Û -> u
  0x1E6D: 0x0074, // ṭ -> t
  0x1E6C: 0x0074, // Ṭ -> t
};

String foldForSearch(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    buffer.writeCharCode(_foldMap[rune] ?? rune);
  }
  return buffer.toString().toLowerCase();
}
