#!/usr/bin/env python3
"""Stage 1 of the Phase 2 content pipeline: PDF -> structured verse data.

Local-only -- no Supabase credentials involved. This script's job is just to
produce trustworthy per-verse text for both languages from the PDF; a later
script seeds that into Supabase, and another exports Supabase to bible.db.
Deliberately kept separate so each stage can be inspected before the next
one runs on top of it.

Usage:
    python tool/extract_pdf.py --book genesis
    python tool/extract_pdf.py --book genesis --json tool/_out/genesis.json
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

PDF_PATH = Path("source_pdfs/THE MIZO ENGLISH PARALLEL BIBLE REV TEXT WITH INSERTS TP 11.pdf")

# Legacy VNTTimes glyph -> Unicode. Derived and empirically validated during
# Phase 1 against an independent Mizo vocabulary list: 87.5%+ direct match
# on ~132,000 diacritic-bearing words, with most of the remainder being real
# alternate spellings, not decode errors. See the plan's Phase 1 section.
CHAR_REMAP = {
    '^': 'â',   # â
    '>': 'ê',   # ê
    '$': 'î',   # î
    '<': 'û',   # û
    '\\': 'ṭ',  # ṭ
    '|': 'Ṭ',   # Ṭ
}

# Chapter counts are standard, well-known facts -- independent ground truth,
# not derived from this PDF. (pdf_first_page/pdf_last_page are 1-indexed PDF
# pages, from the Phase 1 header scan.)
BOOKS = [
    # canonical_id, osis, english_name, chapter_count, pdf_first_page, pdf_last_page
    (1, "Gen", "Genesis", 50, 7, 94),
]

# The separator is normally "." or whitespace, but a chapter-opener can be
# typeset with no separator at all (found directly: "41Then it came to
# pass..." for Genesis 41) -- the lookahead branch covers that specific
# case (digit directly followed by a capital letter) without accepting a
# bare digit run into normal prose, which never happens in this text.
VERSE_RE = re.compile(r'^(\d{1,3})(?:[.\s]|(?=[A-Z]))\s*(.*)$')

# The running header on most pages, e.g.
# "GENESIS 1:30                    3  GENESIS 2:18" -- book+ch:vs on both
# sides plus the book's own internal page number in the middle. Found by
# direct inspection to be the cause of a serious bug: after column-splitting,
# the header's leading page number ("3") sits at the start of the right
# (English) column and was being misread as a verse-3 marker, scrambling
# chapter boundaries on every single page. Must be stripped from the RAW
# (unsplit) line before column-splitting, not handled by VERSE_RE/REF_RE.
HEADER_RE = re.compile(
    r'^\s*([A-Z0-9 .]+?)\s+(\d{1,3}):(\d{1,3})\s+\d+\s+([A-Z0-9 .]+?)\s+(\d{1,3}):(\d{1,3})\s*$'
)
MAX_VERSE = 176  # Psalm 119, the longest chapter in the Bible -- a sanity
                 # bound so a stray number elsewhere can't be mistaken for
                 # a verse marker.

# One scripture citation, e.g. "15:18" (same-book, bare), "Isa. 58:13"
# (book-prefixed), or "2 Kor. 4:6" (a NUMBERED book -- this is the case that
# matters most: it starts with a digit, exactly like a verse marker, which
# is what was corrupting the chapter/verse state machine. See is_reference).
#
# The letter class includes the Mizo diacritics (post-remap: â ê î û ṭ Ṭ),
# not just ASCII -- a Mizo-side reference like "Sâm 6:7" that bleeds into
# the English column is still remapped before reaching here (same reason
# the English parser is remapped too), and an ASCII-only class would make
# that remapping pointless by failing to recognise the result as a letter.
#
# Also includes U+FFFD (the Unicode replacement character): this PDF has
# SIX embedded font subsets (found in Phase 1), and the glyph remap table
# was calibrated against the main body-text font only. A reference run in
# a different subset (observed: an abbreviation for "Psalm") can decode as
# � instead of a recognised character. No genuine Mizo or English word
# ever contains it, so treating it as letter-like here is safe and avoids
# needing to reverse-engineer every font subset's encoding individually.
_ABBR_LETTER = 'A-Za-zÂÊÎÛâêîûṬṭ�'
SINGLE_REF_RE = re.compile(
    rf'^(?:(?:[1-3]\s?)?[{_ABBR_LETTER}][{_ABBR_LETTER}.]{{0,10}}\.?\s*)?'
    r'\d{1,3}:\d{1,3}(?:[,-]\s?\d{1,3})*\.?$'
)


def is_reference(line: str) -> bool:
    """A line (or the tail of one) is a reference if EVERY ';'-separated
    segment is independently a single citation. Composing on ';' handles
    multi-reference lines like "Joh. 1:1,2; Heb. 1:10" and "2 Kor. 4:6;
    Heb. 11:3", which a single monolithic regex couldn't both match."""
    segments = [s.strip() for s in line.split(';')]
    return bool(segments) and all(SINGLE_REF_RE.match(s) for s in segments if s)


# Cross-references are sometimes glued onto the end of a verse's text with
# no separating space (observed directly: "...an la awm hek lo;1:12"), so a
# trailing chunk of a longer line can be a reference even though the whole
# line isn't. This finds the shortest such trailing chunk, starting from
# the last semicolon-or-whitespace boundary and working backward.
REF_TAIL_SPLIT_RE = re.compile(r'[;\s](?=\S)')


def strip_leading_ref(line: str) -> tuple[str | None, str]:
    """Mirror of the trailing case, for the START of a line: on a sparse
    line (little or no real prose), pdftotext's -layout mode positions
    text loosely, so a Mizo-side reference can land past the page's usual
    gutter column and bleed into what gets sliced as the English column
    (observed directly, e.g. a right-column line starting "1:1; S^m
    90:1,2     LORD God had not..."). Finds the LONGEST leading chunk that
    is a clean reference and returns (ref, remainder) -- extending word by
    word only while it still parses as a reference, so it stops exactly at
    the first real prose word."""
    # Deliberately scans every candidate rather than stopping at the first
    # failure: a chained reference like "Jer. 51:13; 2 Pet. 2:4-10" has a
    # momentary dip right at "2" (valid as the start of "2 Pet." but not a
    # reference by itself) that would wrongly end the scan before reaching
    # the second, equally real reference. Lines are short, so scanning all
    # of them costs nothing measurable.
    best_end = None
    for m in re.finditer(r'\s+', line):
        head = line[:m.start()]
        if head and is_reference(head):
            best_end = m.end()
    if best_end is None:
        return None, line
    return line[:best_end].strip(), line[best_end:]


def pdftotext_pages(first: int, last: int) -> list[str]:
    out = subprocess.run(
        ["pdftotext", "-f", str(first), "-l", str(last), "-layout", str(PDF_PATH), "-"],
        capture_output=True, timeout=60,
    )
    return out.stdout.decode("utf-8", errors="replace").split("\f")


def remap(s: str) -> str:
    return "".join(CHAR_REMAP.get(c, c) for c in s)


def join_wrapped(existing: str, new_line: str) -> str:
    """Joins a wrapped continuation line onto a verse's accumulated text.

    A line-wrap hyphen (e.g. "...the wa-" / "ters from the waters") must be
    removed and the two halves joined with no space; anything else joins
    normally with a space. Distinguished from an intentional em-dash
    written as "--" (seen directly in this text, e.g. "the ark--you, your
    sons") by requiring EXACTLY one hyphen at the very end of a line,
    directly preceded by a letter -- "--" fails that (preceded by another
    hyphen, not a letter), so it's never touched.
    """
    # A letter directly before the final hyphen is the wrap case. An
    # em-dash ("--") naturally fails this: the character before ITS final
    # hyphen is another hyphen, not a letter, so it's never mistaken here.
    if re.search(r'[A-Za-z]-$', existing):
        return existing[:-1] + new_line
    return existing + " " + new_line


def find_gutter(lines: list[str]) -> int | None:
    """Longest run of columns blank on >=97% of non-empty lines, in the
    middle half of the page width. None if no clear gutter -- matches the
    threshold validated in Phase 1 (93.6% detection rate on sampled pages)."""
    nonblank = [l for l in lines if l.strip()]
    if len(nonblank) < 5:
        return None
    width = max(len(l) for l in nonblank)
    if width < 60:
        return None
    n = len(nonblank)
    blank_count = [0] * width
    for l in nonblank:
        for c in range(width):
            if c >= len(l) or l[c] == ' ':
                blank_count[c] += 1
    best = None
    run_start = None

    def consider(start, length):
        nonlocal best
        mid_lo, mid_hi = width * 0.25, width * 0.75
        if length >= 3 and mid_lo < start < mid_hi:
            if best is None or length > best[1]:
                best = (start, length)

    for c in range(width):
        if blank_count[c] >= 0.97 * n:
            if run_start is None:
                run_start = c
        else:
            if run_start is not None:
                consider(run_start, c - run_start)
            run_start = None
    if run_start is not None:
        consider(run_start, width - run_start)
    return best[0] if best else None


def local_split_point(line: str, gutter: int, margin: int = 20) -> int:
    """The page's gutter column is computed globally, from where MOST lines
    are blank -- but on a sparse line (e.g. just a cross-reference), found
    directly by inspection, pdftotext's -layout mode can position text
    loosely enough that the real gap sits several characters off from the
    global gutter, and splitting there physically severs a token in half
    (observed: "...Heb. 4:4" split into left "...4" / right ":4"). Finds
    the actual widest blank run within `margin` of the global gutter on
    THIS line and splits there instead, falling back to the global gutter
    if the line has no useful gap nearby (the normal case for most lines,
    where the local and global answers coincide anyway)."""
    lo, hi = max(0, gutter - margin), gutter + margin
    padded = line.ljust(hi)
    best_start, best_len = gutter, 0
    i = lo
    while i < hi:
        if padded[i] == ' ':
            j = i
            while j < hi and padded[j] == ' ':
                j += 1
            run_len = j - i
            center = (i + j) // 2
            if run_len > best_len or (run_len == best_len and abs(center - gutter) < abs(best_start - gutter)):
                best_len, best_start = run_len, center
            i = j
        else:
            i += 1
    return best_start if best_len > 0 else gutter


def split_page_columns(page_text: str) -> tuple[list[str] | None, list[str] | None, str]:
    """Returns (left_lines, right_lines, strategy). Tries the whole page
    first; book-opener pages mix single-column intro prose with two-column
    verse text, which can defeat whole-page gutter detection, so falls back
    to progressively smaller bottom slices (the intro is always at the top)."""
    lines = page_text.split("\n")
    gutter = find_gutter(lines)
    if gutter is not None:
        left, right = [], []
        for l in lines:
            split_at = local_split_point(l, gutter)
            left.append(l[:split_at].rstrip())
            right.append(l[split_at:].rstrip())
        return left, right, "full_page"

    # Book-opener pages mix single-column intro prose (top) with two-column
    # verse text (bottom), and a fixed-fraction cut (tried first: 50%/70%)
    # either keeps too much intro and still fails, or cuts too deep and
    # silently loses real verses -- found directly by inspection: a 50% cut
    # on Genesis's opener lost verses 1-3 entirely. Search for the SMALLEST
    # number of top lines to drop that makes a gutter detectable, so as
    # little real verse content as possible is sacrificed.
    max_search = min(len(lines) - 5, 60)
    for skip in range(1, max_search):
        sub = lines[skip:]
        gutter = find_gutter(sub)
        if gutter is not None:
            left, right = [], []
            for l in sub:
                split_at = local_split_point(l, gutter)
                left.append(l[:split_at].rstrip())
                right.append(l[split_at:].rstrip())
            return left, right, f"skip_top_{skip}_lines"

    return None, None, "no_gutter_detected"


def load_reference_counts() -> dict[int, list[int]]:
    """Per-chapter verse counts, derived from KJV (see tool/reference/ --
    generated once from the same JSON used during Phase 1 research, not
    hand-transcribed). Used only as a tie-breaker for one specific
    ambiguity: when a chapter happens to have exactly as many verses as
    its own number (Genesis 16 has 16 verses, Genesis 32 has 32), the next
    marker numerically matches BOTH "next verse" and "next chapter" at
    once, and the bare number can't disambiguate itself. This text may
    occasionally divide a verse differently than KJV, so it's a strong
    prior for breaking a tie, not an authority overriding a clean parse."""
    path = Path(__file__).parent / "reference" / "kjv_verse_counts.json"
    raw = json.loads(path.read_text(encoding="utf-8"))
    return {int(k): v for k, v in raw.items()}


class ColumnParser:
    """State machine over one column's lines for one book.

    Key fact this encodes, found by direct inspection (not assumed): the
    first verse of a new chapter shows the CHAPTER number in place of a
    verse-1 marker (e.g. Genesis 2 opens with a bare "2", not "1"), so a
    verse number that doesn't continue the sequence is treated as a chapter
    boundary rather than an error -- with the jump logged as an anomaly if
    it isn't exactly +1, so a genuine mis-parse still surfaces.
    """

    def __init__(self, canonical_id: int, reference_counts: dict[int, list[int]] | None = None):
        self.canonical_id = canonical_id
        self.reference_counts = (reference_counts or {}).get(canonical_id, [])
        self.chapter = 0
        self.verse = 0
        self.verses: dict[tuple[int, int], str] = {}
        self.refs: dict[tuple[int, int], list[str]] = {}
        self.headings: dict[tuple[int, int], str] = {}
        self.pending_heading_lines: list[str] = []
        self.cur_key: tuple[int, int] | None = None
        self.anomalies: list[tuple] = []

    def feed_line(self, raw: str) -> None:
        line = raw.strip()
        if not line:
            return

        # Checked BEFORE the verse regex, deliberately: a numbered-book
        # reference like "2 Kor. 4:6" starts with a digit+space exactly
        # like a verse marker. Checking VERSE_RE first (the original bug)
        # let every such reference masquerade as a verse number and
        # scrambled the chapter/verse state machine.
        if is_reference(line):
            if self.cur_key:
                self.refs.setdefault(self.cur_key, []).append(line)
            else:
                self.anomalies.append(("orphan_ref", line))
            return

        lead_ref, remainder = strip_leading_ref(line)
        if lead_ref is not None:
            if self.cur_key:
                self.refs.setdefault(self.cur_key, []).append(lead_ref)
            line = remainder.strip()
            if not line:
                return

        m = VERSE_RE.match(line)
        if m and int(m.group(1)) <= MAX_VERSE:
            self._start_verse(int(m.group(1)), m.group(2))
            return

        if self.cur_key:
            self.verses[self.cur_key] = join_wrapped(self.verses[self.cur_key], line)
        else:
            self.pending_heading_lines.append(line)

    def _start_verse(self, num: int, text: str) -> None:
        # Deliberately strict: a bare number is ambiguous between "next
        # verse" and "next chapter" (the chapter-opener convention), and
        # chapters are never observed to skip or go backward in this text.
        # So only the two transitions that can actually happen are accepted;
        # anything else (almost always a malformed reference that slipped
        # past is_reference, e.g. missing its ":verse" half) is rejected
        # rather than guessed at -- a dropped line is far safer than
        # silently overwriting an already-correct verse at a reused key.
        if self.chapter == 0:
            self.chapter, self.verse = 1, 1
            if num != 1:
                self.anomalies.append(("first_verse_not_1", num, text))
        elif num == self.verse + 1 and num == self.chapter + 1:
            # The genuine ambiguity: both interpretations match the same
            # number. Break the tie using the real verse count of the
            # CURRENT chapter -- if it's full (self.verse already equals
            # its expected last verse), this must be the next chapter
            # opening, not an overrun continuation.
            expected_last = (
                self.reference_counts[self.chapter - 1]
                if 0 < self.chapter <= len(self.reference_counts)
                else None
            )
            if expected_last is not None and self.verse >= expected_last:
                self.chapter, self.verse = num, 1
            else:
                self.verse = num
        elif num == self.verse + 1:
            self.verse = num
        elif num == self.chapter + 1:
            self.chapter, self.verse = num, 1
        else:
            self.anomalies.append(
                ("rejected", f"after ch{self.chapter}:v{self.verse}", f"saw {num}", text)
            )
            return
        self.cur_key = (self.chapter, self.verse)
        self.verses[self.cur_key] = text
        if self.pending_heading_lines:
            self.headings[self.cur_key] = " ".join(self.pending_heading_lines)
            self.pending_heading_lines = []

    def strip_trailing_refs(self) -> int:
        """Post-process pass: a reference glued onto the end of a verse's
        text with no separating space (seen directly in the PDF, e.g.
        "...hek lo;1:12") can't be caught line-by-line since it isn't its
        own line. Try progressively longer trailing chunks -- split at each
        ';' or whitespace boundary from the end -- and strip the shortest
        one that's a clean reference. Returns how many verses were touched."""
        n = 0
        for key, text in list(self.verses.items()):
            # Forward order, first (leftmost) match wins: this greedily
            # captures the LONGEST valid trailing reference, so a multi-word
            # citation like "2 Kor. 4:6" is stripped whole rather than just
            # its last word. is_reference's all-segments check keeps this
            # from ever eating into real prose, which won't pass it.
            for m in REF_TAIL_SPLIT_RE.finditer(text):
                tail = text[m.end():]
                if is_reference(tail):
                    cleaned = text[: m.start()].rstrip().rstrip(';').rstrip()
                    if cleaned:
                        self.refs.setdefault(key, []).append(tail)
                        self.verses[key] = cleaned
                        n += 1
                    break
        return n


def strip_header_line(page_text: str):
    """Finds the running-header line (if any), blanks it out of the page
    text, and returns (page_text_without_header, parsed_header_or_None)."""
    lines = page_text.split("\n")
    header = None
    for i, l in enumerate(lines):
        m = HEADER_RE.match(l.strip())
        if m:
            header = m.groups()
            lines[i] = ""
            break  # headers only ever appear once, near the top of the page
    return "\n".join(lines), header


def extract_book(canonical_id, osis, name, chapter_count, first_page, last_page):
    pages = pdftotext_pages(first_page, last_page)
    ref_counts = load_reference_counts()
    mizo = ColumnParser(canonical_id, ref_counts)
    eng = ColumnParser(canonical_id, ref_counts)
    page_strategies = []
    headers = []

    for i, page_text in enumerate(pages):
        pdf_page_num = first_page + i
        page_text, header = strip_header_line(page_text)
        if header:
            headers.append((pdf_page_num, header))
        left_lines, right_lines, strategy = split_page_columns(page_text)
        page_strategies.append((pdf_page_num, strategy))
        if left_lines is None:
            continue
        for raw in left_lines:
            mizo.feed_line(remap(raw))
        for raw in right_lines:
            # A Mizo-side reference that bleeds into the English slice
            # (sparse-line column drift, e.g. "S^m 6:7") carries Mizo's
            # legacy encoding regardless of which column it lands in, and
            # unremapped it doesn't parse as a reference at all -- the "^"
            # isn't a letter, so "S^m" doesn't look like a citation prefix.
            # Safe to remap English too: none of these ASCII punctuation
            # characters have a legitimate meaning in English Bible prose.
            eng.feed_line(remap(raw))

    mizo_stripped = mizo.strip_trailing_refs()
    eng_stripped = eng.strip_trailing_refs()
    return mizo, eng, page_strategies, mizo_stripped, eng_stripped, headers


def main():
    # Windows' default console codepage (cp1252) can't print the Mizo
    # diacritics; force UTF-8 regardless of platform rather than relying on
    # PYTHONIOENCODING being set in the caller's shell.
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

    ap = argparse.ArgumentParser()
    ap.add_argument("--book", default="genesis")
    ap.add_argument("--json", default=None)
    args = ap.parse_args()

    try:
        book = next(b for b in BOOKS if b[2].lower() == args.book.lower())
    except StopIteration:
        print(f"Unknown or not-yet-configured book: {args.book}", file=sys.stderr)
        sys.exit(1)
    canonical_id, osis, name, chapter_count, first_page, last_page = book

    mizo, eng, page_strategies, mizo_stripped, eng_stripped, headers = extract_book(
        canonical_id, osis, name, chapter_count, first_page, last_page
    )
    print(f"Running headers found on {len(headers)} / {last_page - first_page + 1} pages")

    print(f"=== {name} (PDF pages {first_page}-{last_page}) ===")
    print(f"Mizo verses parsed:        {len(mizo.verses):5d}   reached chapter {mizo.chapter} / {chapter_count}")
    print(f"English verses parsed:     {len(eng.verses):5d}   reached chapter {eng.chapter} / {chapter_count}")
    print(f"Trailing refs stripped:    Mizo {mizo_stripped}, English {eng_stripped}")

    strategy_counts: dict[str, int] = {}
    for _, s in page_strategies:
        strategy_counts[s] = strategy_counts.get(s, 0) + 1
    print(f"Page split strategies used: {strategy_counts}")
    skipped = [p for p, s in page_strategies if s == "no_gutter_detected"]
    if skipped:
        print(f"  PAGES FULLY SKIPPED (no gutter at any fallback level): {skipped}")

    print()
    print(f"--- Mizo anomalies ({len(mizo.anomalies)}) ---")
    for a in mizo.anomalies[:25]:
        print(" ", a)
    print(f"--- English anomalies ({len(eng.anomalies)}) ---")
    for a in eng.anomalies[:25]:
        print(" ", a)

    print()
    print("--- Chapter 1, verses 1-5 ---")
    for v in range(1, 6):
        print(f"  Mizo    {v}: {mizo.verses.get((1, v), '<<MISSING>>')}")
        print(f"  English {v}: {eng.verses.get((1, v), '<<MISSING>>')}")

    print()
    print("--- Chapter 2, verses 1-4 (tests the chapter-boundary logic) ---")
    for v in range(1, 5):
        print(f"  Mizo    {v}: {mizo.verses.get((2, v), '<<MISSING>>')}")
        print(f"  English {v}: {eng.verses.get((2, v), '<<MISSING>>')}")

    print()
    print(f"--- Headings found (Mizo side): {len(mizo.headings)} ---")
    for k, v in list(mizo.headings.items())[:10]:
        print(f"  {k}: {v!r}")

    print()
    print(f"--- Refs found (Mizo side): {sum(len(v) for v in mizo.refs.values())} total ---")
    for k, v in list(mizo.refs.items())[:10]:
        print(f"  {k}: {v}")

    # Count mismatch between the two languages -- expected to be small
    # (the earlier CL1995/KJV research found 49/1189 chapters differ;
    # this PDF, being a hand-typeset parallel edition, may do better).
    mizo_keys, eng_keys = set(mizo.verses), set(eng.verses)
    print()
    print(f"--- Verse-key alignment: Mizo-only {len(mizo_keys - eng_keys)}, "
          f"English-only {len(eng_keys - mizo_keys)}, shared {len(mizo_keys & eng_keys)} ---")

    if args.json:
        out_path = Path(args.json)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        data = {
            "book": name,
            "mizo": {f"{c}:{v}": t for (c, v), t in mizo.verses.items()},
            "english": {f"{c}:{v}": t for (c, v), t in eng.verses.items()},
            "mizo_refs": {f"{c}:{v}": r for (c, v), r in mizo.refs.items()},
            "mizo_headings": {f"{c}:{v}": h for (c, v), h in mizo.headings.items()},
        }
        out_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"\nWrote {out_path}")


if __name__ == "__main__":
    main()
