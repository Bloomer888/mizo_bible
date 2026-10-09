/// One row in the continuous reader list for a single book.
///
/// A flat sealed list (rather than a nested chapter->section->verse tree)
/// is what [scrollable_positioned_list](https://pub.dev/packages/scrollable_positioned_list)
/// needs: it indexes and jumps by flat list position, so chapter/section
/// boundaries have to be ordinary items in that same list, not a separate
/// structure layered on top.
sealed class ReaderItem {
  const ReaderItem();
}

/// Marks the start of a new chapter. Chapter numbers aren't
/// per-translation content, so this carries just the number, rendered
/// full-width rather than split into two columns.
final class ChapterHeader extends ReaderItem {
  final int chapter;
  const ChapterHeader(this.chapter);
}

/// A section heading preceding the verse at [chapter]/[verse] -- e.g.
/// Genesis 1:1's "Thil siam Chanchin" / "The History of Creation". Each
/// side is independent: one language's extraction can carry a heading the
/// other doesn't, so both are nullable rather than assuming they pair up.
final class SectionHeading extends ReaderItem {
  final int chapter;
  final int verse;
  final String? a;
  final String? b;
  const SectionHeading({required this.chapter, required this.verse, this.a, this.b});
}

/// One parallel_rows alignment row rendered as a Row: [a] and [b] side by
/// side, selection and scrolling operate on this whole unit, never on one
/// language alone -- see the plan's Phase 5 notes on why two independently
/// scrolling lists don't work here.
final class VerseRow extends ReaderItem {
  final int chapter;
  final String label;
  final String? a;
  final String? b;
  const VerseRow({required this.chapter, required this.label, this.a, this.b});
}
