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
import statistics
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
# pages, from a full-document running-header scan done after Genesis proved
# the pipeline out -- see the Phase 2 commit for how.)
BOOKS = [
    # canonical_id, osis, english_name, chapter_count, pdf_first_page, pdf_last_page
    # Chained so each book's start is the previous book's end + 1 (catches
    # opener pages, which never carry a header of their own -- same pattern
    # as Genesis page 7). Three very short books (Lamentations, 2 John,
    # Jude) never produced a header match at all and were positioned from
    # their neighbours' detected boundaries instead -- one of those
    # estimates was off by a page: 3 John's own verses 13-14 run onto what
    # was originally marked as Jude's first page, found directly when
    # Jude's own extraction opened with 3 John's running header and a bare
    # "13" read as if it were Jude's own verse 1.
    (1, "Gen", "Genesis", 50, 7, 94),
    (2, "Exod", "Exodus", 40, 95, 167),
    (3, "Lev", "Leviticus", 27, 168, 218),
    (4, "Num", "Numbers", 36, 219, 290),
    (5, "Deut", "Deuteronomy", 34, 291, 351),
    (6, "Josh", "Joshua", 24, 352, 393),
    (7, "Judg", "Judges", 21, 394, 434),
    (8, "Ruth", "Ruth", 4, 435, 440),
    (9, "1Sam", "1 Samuel", 31, 441, 495),
    (10, "2Sam", "2 Samuel", 24, 496, 542),
    (11, "1Kgs", "1 Kings", 22, 543, 596),
    (12, "2Kgs", "2 Kings", 25, 597, 647),
    (13, "1Chr", "1 Chronicles", 29, 648, 697),
    (14, "2Chr", "2 Chronicles", 36, 698, 754),
    (15, "Ezra", "Ezra", 10, 755, 771),
    (16, "Neh", "Nehemiah", 13, 772, 796),
    (17, "Esth", "Esther", 10, 797, 809),
    (18, "Job", "Job", 42, 810, 863),
    (19, "Ps", "Psalms", 150, 864, 1009),
    (20, "Prov", "Proverbs", 31, 1010, 1055),
    (21, "Eccl", "Ecclesiastes", 12, 1056, 1070),
    (22, "Song", "Song of Solomon", 8, 1071, 1080),
    (23, "Isa", "Isaiah", 66, 1081, 1185),
    (24, "Jer", "Jeremiah", 52, 1186, 1287),
    (25, "Lam", "Lamentations", 5, 1288, 1297),
    (26, "Ezek", "Ezekiel", 48, 1298, 1385),
    (27, "Dan", "Daniel", 12, 1386, 1413),
    (28, "Hos", "Hosea", 14, 1414, 1429),
    (29, "Joel", "Joel", 3, 1430, 1436),
    (30, "Amos", "Amos", 9, 1437, 1448),
    (31, "Obad", "Obadiah", 1, 1449, 1451),
    (32, "Jonah", "Jonah", 4, 1452, 1455),
    (33, "Mic", "Micah", 7, 1456, 1465),
    (34, "Nah", "Nahum", 3, 1466, 1470),
    (35, "Hab", "Habakkuk", 3, 1471, 1475),
    (36, "Zeph", "Zephaniah", 3, 1476, 1481),
    (37, "Hag", "Haggai", 2, 1482, 1484),
    (38, "Zech", "Zechariah", 14, 1485, 1501),
    (39, "Mal", "Malachi", 4, 1502, 1507),
    (40, "Matt", "Matthew", 28, 1508, 1571),
    (41, "Mark", "Mark", 16, 1572, 1610),
    (42, "Luke", "Luke", 24, 1611, 1675),
    (43, "John", "John", 21, 1676, 1723),
    (44, "Acts", "Acts", 28, 1724, 1784),
    (45, "Rom", "Romans", 16, 1785, 1810),
    (46, "1Cor", "1 Corinthians", 16, 1811, 1836),
    (47, "2Cor", "2 Corinthians", 13, 1837, 1853),
    (48, "Gal", "Galatians", 6, 1854, 1862),
    (49, "Eph", "Ephesians", 6, 1863, 1871),
    (50, "Phil", "Philippians", 4, 1872, 1878),
    (51, "Col", "Colossians", 4, 1879, 1884),
    (52, "1Thess", "1 Thessalonians", 5, 1885, 1890),
    (53, "2Thess", "2 Thessalonians", 3, 1891, 1893),
    (54, "1Tim", "1 Timothy", 6, 1894, 1900),
    (55, "2Tim", "2 Timothy", 4, 1901, 1906),
    (56, "Titus", "Titus", 3, 1907, 1909),
    (57, "Phlm", "Philemon", 1, 1910, 1911),
    (58, "Heb", "Hebrews", 13, 1912, 1931),
    (59, "Jas", "James", 5, 1932, 1938),
    (60, "1Pet", "1 Peter", 5, 1939, 1946),
    (61, "2Pet", "2 Peter", 3, 1947, 1951),
    (62, "1John", "1 John", 5, 1952, 1958),
    (63, "2John", "2 John", 1, 1959, 1959),
    (64, "3John", "3 John", 1, 1960, 1961),
    (65, "Jude", "Jude", 1, 1962, 1964),
    (66, "Rev", "Revelation", 22, 1965, 1995),
]

# The separator is normally "." or whitespace, but a chapter-opener can be
# typeset with no separator at all (found directly: "41Then it came to
# pass..." for Genesis 41, and "31"At the same time," for Jeremiah 31 --
# the second shows the number can also run straight into an opening quote
# before the capital letter). The lookahead covers both, with an optional
# quote mark, without accepting a bare digit run into normal prose, which
# never happens in this text. The backtick is this text's other opening
# quote style (found directly: Numbers 29's own chapter-opener, "29`Thla
# sarihna..."), used over 2,300 times and essentially always immediately
# before a capital letter, so added here the same way -- the real guard
# stays _would_accept's exact verse+1/chapter+1 match, same as every
# other marker shape.
VERSE_RE = re.compile(r'^(\d{1,3})(?:[.\s]|(?=["“`]?[A-Z]))\s*(.*)$')

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

# Poetry books don't necessarily use the "chapter number stands in for
# verse 1" convention narrative books do -- found directly: Psalms gives
# each psalm its own standalone title line ("SAM 2" / "PSALM 2", on both
# sides), with verse 1 then typeset as a plain, unambiguous "1". Kept
# book-agnostic (not gated to "only when the current book is Psalms") --
# the strict num == chapter + 1 check in feed_line that consumes this is
# the actual safety net, so a coincidental match elsewhere is simply
# rejected there rather than needing to be filtered out here.
CHAPTER_TITLE_RE = re.compile(r'^[A-Za-zÂÊÎÛâêîûṬṭ]{2,20}\s+(\d{1,3})$')

# "Selah" (kept as-is, untranslated, on both the Mizo and English sides) is
# a liturgical pause-marker, not verse text. On its own line it's already
# handled fine -- it just joins onto the current verse like any other
# continuation. The harmful case, found directly, is "Selah" sharing a
# line with the START of the NEXT verse ("Selah  4 My soul is among
# lions"), which hides that verse's marker from VERSE_RE entirely.
SELAH_LEAD_RE = re.compile(r'^Selah\s+(?=\d)')

# The mirror image of a leading marker: a continuation line can carry the
# NEXT verse's bare marker instead of it starting a fresh line. Two shapes,
# unified into one pattern: the marker can be the LAST thing on the line
# ("...maiin ka siam ang.          18", verse 18's text continuing on the
# NEXT line), or short verses can run together inline on ONE line, marker
# and all ("...Libni and Shimei. 19 And the", found directly in Numbers
# 3:18-19 -- group 3 here is the start of verse 19's own text, present on
# the SAME line). VERSE_RE only ever looks at the START of a line, so this
# needs its own check regardless of which shape it is. Neither the gap
# width nor "is there trailing text" is the safety net -- the actual bar is
# requiring the number to pass _would_accept (exactly verse+1 or
# chapter+1) before it's trusted, same as everywhere else a bare number
# gets a second look. Group 3 doesn't require a capital letter -- found
# directly, Numbers 4:36 continues 4:35's sentence grammatically ("...work
# in the tabernacle of meeting; 36 and those who were numbered..."), the
# same lowercase-continuation shape 1 Peter 2:3 has. Safe for the same
# reason the capital check was never the real safety net here: it's
# _would_accept's strict numeric match that does the actual work, and a
# coincidental "number + lowercase word" has to also hit verse+1 or
# chapter+1 exactly before it's ever trusted.
TRAILING_MARKER_RE = re.compile(r'^(.*\S)\s+(\d{1,3})(?:\s+(.*))?$')

# A further guard for the trailing-marker check below: a chain of bare,
# colon-less, period-less chapter citations ("Rom 15; 10; 12", found
# directly in Isaiah 11 -- Romans 15, then two more chapters of the
# current book) leaves the text right before the final number ending in
# "; N;" or similar -- itself still shaped like a reference, not like the
# end of a real sentence. is_reference on the tail alone (just "12")
# doesn't catch this, since a lone number is deliberately never a
# reference by itself; this catches it from the OTHER side instead.
REF_CHAIN_TAIL_RE = re.compile(r';\s*\d{1,3}\s*;\s*$')

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
# The abbreviation body tolerates ONE embedded space (found directly:
# "I sa. 9:13" for what should be "Isa." -- the same kind of mid-token
# spacing quirk already handled for chapter markers, "1 7Then" for "17").
# Still bounded to {0,10} total characters, so this can't swallow a real
# multi-word sentence -- a genuine abbreviation is always short.
# One reference unit, as any of four shapes. No anchors here -- this is a
# fragment, reused below to match a RUN of these back to back, which is
# what a real multi-reference line actually is.
#
# Three are same-chapter shorthand with no book prefix, each skipping a
# different part of "chapter:verse": a bare "N-M" range with no colon at
# all ("1-11; 9-11; 18:1; Jud. 9:8"), a bare ":M-N" WITH a colon but no
# chapter number before it (":12-18; Jer. 34:8-14", Exodus 21), and the
# ordinary bare "N:M" with no book name ("15:18"). Kept as separate
# branches rather than making any one part optional in a single pattern,
# so an ordinary citation still requires what it actually needs.
#
# The fourth and fifth both take a book prefix. The fourth is an ordinary
# "prefix + chapter:verse" citation ("Isa. 58:13", "Rom 2:8,9" -- the
# latter confirmed with NO period at all, so the period after a prefix
# stays optional there, same as always; the colon is what makes it safe).
# The fifth lets the verse half be entirely absent -- a whole-chapter
# citation ("Jer. 16", found directly in Proverbs 15, referencing all of
# Jeremiah 16) -- and there the period is made MANDATORY, because without
# a colon to lean on, "prefix + bare number" is dangerously easy to
# satisfy by accident: ordinary Mizo prose regularly reads as "short
# phrase, then a number" (found directly: "Ban ding 45 chungah..." was
# being swallowed as if "Ban ding" were a book name and 45 its chapter,
# corrupting 1 Kings 7 onward). A real abbreviation always has the period
# typeset; ordinary prose essentially never does right before a number.
_PREFIX = rf'(?:[1-3]\s?)?[{_ABBR_LETTER}][{_ABBR_LETTER} ]{{0,9}}'
# The colon itself tolerates one space on EITHER side -- found directly:
# "1 Lal. 18: 21" for "1 Kings 18:21" (Psalm 119, space after) and "35
# :11" for "35:11" (Job 39:16, space before) are the same incidental
# pdftotext layout-spacing artifact as the comma/dash tolerance right
# next to it in this same pattern ("[,-]\s?\d"); the colon just hadn't
# been given the same allowance on both sides yet.
#
# The dash-separated repeat can itself carry a second ":verse" -- a range
# that crosses a CHAPTER boundary ("1 Lal. 22:1-23:30", found directly in
# Zephaniah's opening cross-reference chain, alongside "2 Chro.
# 34:1-35:27" right next to it). Without this, is_reference failed on the
# whole chain, and the strict verse-marker check downstream mistook its
# second reference's leading "2" for a real verse-2 marker trailing the
# first -- a worse failure than the plain rejection this gap used to
# cause, since now it actively started two fake verses instead of
# dropping one anomalous line.
#
# The separator also accepts a period, not just comma/dash -- found
# directly in exactly 3 places across the whole corpus (1 Samuel 20:1.26,
# 2 Kings 8:27's "2 Chro. 22:3.4", John 5:6.8): a plain typo, a period
# typed where a comma was meant, rare enough to confirm by exhaustive
# search rather than guess at.
_REF_UNIT = (
    rf'(?:{_PREFIX}\.?\s*\d{{1,3}}\s?:\s?\d{{1,3}}(?:[,.-]\s?\d{{1,3}}(?::\d{{1,3}})?)*'
    rf'|{_PREFIX}\.\s*\d{{1,3}}'
    r'|\d{1,3}\s?:\s?\d{1,3}(?:[,.-]\s?\d{1,3}(?::\d{1,3})?)*'
    r'|\d{1,3}-\d{1,3}'
    r'|:\s?\d{1,3}(?:[,.-]\s?\d{1,3}(?::\d{1,3})?)*'
    r')\.?'
)
# A full reference line/tail is one REAL unit (colon or dash required --
# see _REF_UNIT), then zero or more further units. A further unit can be
# another real one (separated by ';', ',', or just a bare space, found
# directly: "Deut. 28:13 Sâm 14:7; I sa. 12:5,6"), OR a bare number with
# NEITHER colon nor dash -- found directly, "8:8; 15" cites verse 15 of
# the same chapter -- but a bare number is indistinguishable from a plain
# verse marker in isolation, so it's only accepted right after a literal
# ';', never after a plain space. That space-vs-semicolon distinction is
# what a reference-list continuation and "a reference followed by the
# next real verse starting on the same line" actually look like here, and
# requiring a real unit FIRST already keeps a lone "15" from matching at
# all on its own.
#
# The gap after that semicolon is capped at one space, not unbounded --
# found directly, Job 38:9's "26:10;     10 When I fixed My limit for
# it," has a REAL verse-10 marker sitting 5 spaces after a Mizo-side
# reference, on a row with no other Mizo text to anchor the column
# split. An unbounded gap there let is_reference (via strip_leading_ref)
# swallow the real marker as if it were one more chained citation,
# losing verse 10 as cleanly as if it had never been typeset. "8:8; 15"
# -- the case this alternative exists for -- only ever needs one space.
_REF_CONT = rf'(?:[;,\s]+{_REF_UNIT}|;\s?\d{{1,3}}\.?)'
MULTI_REF_RE = re.compile(rf'^{_REF_UNIT}{_REF_CONT}*[;,\s]*$')


def is_reference(line: str) -> bool:
    """Whether a line (or the tail of one) is nothing but reference
    citations -- one, or several back to back, in any mix of the
    separators this text actually uses between them."""
    return bool(line) and bool(MULTI_REF_RE.match(line))


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
    # A translator's footnote ("*Galili Dil; Lk. 5:1 ...", a marginal note
    # on a Hebrew/Greek term or place name, marked with a leading "*" and
    # used ~80 times in this text) isn't itself reference-shaped, so the
    # scan below never recognizes it on its own -- harmless everywhere
    # else, since real Mizo verse text normally shares the row and anchors
    # the column split regardless, but found directly to matter on Numbers
    # 34:12, whose whole physical row is nothing BUT one of these plus the
    # real next verse's marker, with no other Mizo text on the row at all.
    # Tried only as a prefix to the real scan below, and only kept if a
    # real reference is actually found after it -- a leading "*" alone
    # proves nothing.
    m_foot = re.match(r'\*[^;]*;\s*', line)
    foot_prefix, scan_line = (m_foot.group(0), line[m_foot.end():]) if m_foot else ("", line)

    # Deliberately scans every candidate rather than stopping at the first
    # failure: a chained reference like "Jer. 51:13; 2 Pet. 2:4-10" has a
    # momentary dip right at "2" (valid as the start of "2 Pet." but not a
    # reference by itself) that would wrongly end the scan before reaching
    # the second, equally real reference. Lines are short, so scanning all
    # of them costs nothing measurable.
    best_end = None
    for m in re.finditer(r'\s+', scan_line):
        head = scan_line[:m.start()]
        if head and is_reference(head):
            best_end = m.end()
    if best_end is None:
        return None, line
    return (foot_prefix + scan_line[:best_end]).strip(), scan_line[best_end:]


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
    if not existing:
        # A verse opened by a trailing marker (see TRAILING_MARKER_RE)
        # starts with no text of its own -- the real text only arrives via
        # continuation lines. Avoids a permanent leading space from the
        # "existing + ' ' + new_line" path below.
        return new_line
    # A letter directly before the final hyphen is the wrap case. An
    # em-dash ("--") naturally fails this: the character before ITS final
    # hyphen is another hyphen, not a letter, so it's never mistaken here.
    if re.search(r'[A-Za-z]-$', existing):
        return existing[:-1] + new_line
    return existing + " " + new_line


def _gutter_candidates(lines: list[str]) -> list[tuple[int, int]]:
    """Every maximal run of columns blank on >=97% of non-empty lines, in
    the middle half of the page width -- the raw candidate list shared by
    `find_gutter`'s hinted and hintless modes."""
    nonblank = [l for l in lines if l.strip()]
    if len(nonblank) < 5:
        return []
    width = max(len(l) for l in nonblank)
    if width < 60:
        return []
    n = len(nonblank)
    blank_count = [0] * width
    for l in nonblank:
        for c in range(width):
            if c >= len(l) or l[c] == ' ':
                blank_count[c] += 1
    mid_lo, mid_hi = width * 0.25, width * 0.75
    candidates = []
    run_start = None

    def consider(start, length):
        # A dense page (found directly: Exodus 22-23's short, reference-
        # heavy legal-code verses) can have a gutter only 1 column wide --
        # the 97% blank threshold above is already a strong filter, so
        # requiring extra width on top of it only rejects genuine gutters.
        if length >= 1 and mid_lo < start < mid_hi:
            candidates.append((start, length))

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
    return candidates


def find_gutter(lines: list[str], hint: float | None = None) -> int | None:
    """Picks the real gutter among the candidate blank-column runs. None if
    no candidate qualifies -- matches the threshold validated in Phase 1
    (93.6% detection rate on sampled pages).

    Without a hint, the widest run wins (the original rule, still the right
    default for a page with only one real candidate -- the normal case).
    With a hint, the run closest to it wins instead: found directly on
    Psalm 119's pages, whose short, choppy verse-continuation lines leave
    enough stray blank space that SEVERAL columns pass the 97% threshold,
    and the real gutter isn't reliably the widest one among them. `hint` is
    this book's own consensus gutter column (see extract_book) -- every
    page in a book shares one fixed print layout, so where most pages agree
    is strong independent evidence for where an ambiguous page's gutter
    actually is."""
    candidates = _gutter_candidates(lines)
    if not candidates:
        return None
    if hint is None:
        best = None
        for start, length in candidates:
            if best is None or length > best[1]:
                best = (start, length)
        return best[0]
    start, _ = min(candidates, key=lambda sl: (abs(sl[0] - hint), -sl[1]))
    return start


def _widest_run_in_window(line: str, lo: int, hi: int, gutter: int) -> tuple[int, int]:
    """Widest blank run within [lo, hi), tie-broken by closeness to
    `gutter`. Returns (start, length); length is 0 if nothing qualifies.

    `hi` is capped to the line's own length -- found directly, Matthew
    10:31's whole line (both languages' short verse 31, nothing else) is
    only 93 characters long, but gutter + the wider margin reaches to 98.
    Padding past the real end of the line to let the window reach that
    far manufactures a fake "blank run" out of nothing but the absence of
    any more text, and it was winning as the widest candidate -- pushing
    the split past ALL of the line's real content and handing the entire
    line, English half included, to the Mizo side. Capping costs nothing
    for the case padding was originally meant for (one side genuinely
    blank for this row): slicing a string past its own length already
    degrades gracefully to "everything" / "nothing", exactly as wanted,
    with no fake run required to get there."""
    hi = min(hi, len(line))
    best_start, best_len = gutter, 0
    i = lo
    while i < hi:
        if line[i] == ' ':
            j = i
            while j < hi and line[j] == ' ':
                j += 1
            run_len = j - i
            center = (i + j) // 2
            if run_len > best_len or (run_len == best_len and abs(center - gutter) < abs(best_start - gutter)):
                best_len, best_start = run_len, center
            i = j
        else:
            i += 1
    return best_start, best_len


def local_split_point(line: str, gutter: int, margins: tuple[int, ...] = (20, 30)) -> int:
    """The page's gutter column is computed globally, from where MOST lines
    are blank -- but on a sparse line (e.g. just a cross-reference), found
    directly by inspection, pdftotext's -layout mode can position text
    loosely enough that the real gap sits several characters off from the
    global gutter, and splitting there physically severs a token in half
    (observed: "...Heb. 4:4" split into left "...4" / right ":4"). Finds the
    WIDEST blank run within the first margin of `margins` and splits there,
    same rule as always; only widens to the next margin if that one found
    NOTHING at all (a run >=2 wide -- see below), rather than always
    searching the widest margin up front. That distinction matters: widest
    wins reliably within a line's own real column gap, but a wider search
    window can also reach an unrelated, incidentally-wider gap elsewhere on
    the same line (a line's leading indentation, or a plain word-gap in
    running prose) that has nothing to do with the real boundary -- found
    directly, this broke Exodus and Jeremiah when the wider margin was
    tried unconditionally. Escalating only on a dead end at the narrower
    margin keeps every line that already works today exactly as it was,
    and only reaches further for a line like Nehemiah 9:16's, whose long
    reference chain ("Ex. 16:14; Num. 20:8; Joh. 6:31; 1 Kor. 10:4") pushes
    the real gap further from the global gutter than any line had needed
    before."""
    best_start, best_len = gutter, 0
    for margin in margins:
        lo, hi = max(0, gutter - margin), gutter + margin
        best_start, best_len = _widest_run_in_window(line, lo, hi, gutter)
        if best_len >= 2:
            break
    # Require more than ordinary word-spacing (a single space) before
    # overriding the global gutter -- found directly: on a line where one
    # side has no content at all (e.g. a short Mizo verse that ends on the
    # previous line, leaving this line all-English), every normal
    # word-break in that prose ties at length 1, and the nearest-to-gutter
    # tie-break was slicing real sentences in half at a random word
    # boundary. A genuine local shift can still be narrow, though -- a
    # reference crowded right up against the next verse marker (found
    # directly: "Thup. 14:6  3 For...") can have as little as a 2-space
    # gap -- so >=2, not a wider margin, is what actually separates "every
    # candidate ties at 1" from "a real, if tight, gap".
    if best_len >= 2:
        return best_start
    # Last resort, found directly: John 10:6's line has NO gap anywhere
    # near the gutter wider than ordinary word-spacing (every candidate
    # ties at 1, same shape the >=2 rule above is deliberately guarding
    # against) -- but the raw gutter itself then lands inside a real word
    # ("used" -> "us" / "ed"), because the English column's own verse
    # marker is wedged between two single-space gaps too narrow to ever
    # qualify above. Requiring the marker to be followed by a capitalized
    # word (tried first) is both too strict -- 1 Peter 2:3 opens lowercase
    # ("3 if indeed...", continuing 2:2's sentence) -- and, loosened to
    # any word, too loose: it started firing on ordinary prose elsewhere
    # and regressed five previously-clean books. The signal that's
    # actually specific enough: this line's OWN leading verse marker (both
    # languages often start a fresh verse on the same physical row) shows
    # up a SECOND time near the gutter -- e.g. this line starts "6 Isua'n
    # ..." and later has "...eng 6 Jesus used...", the same "6" twice.
    # That exact repetition is vanishingly unlikely in ordinary prose, so
    # trusted even at this width: split right before the second
    # occurrence, giving it entirely to whichever column it actually
    # starts.
    lead = re.match(r'\s*(\d{1,3})[.\s]', line)
    if lead:
        marker = lead.group(1)
        lo, hi = max(0, gutter - margins[-1]), gutter + margins[-1]
        best_dist = None
        for m in re.finditer(rf'(?<=\S ){re.escape(marker)} (?=\S)', line):
            if lead.end() <= m.start() and lo <= m.start() < hi and (
                best_dist is None or abs(m.start() - gutter) < best_dist
            ):
                best_start, best_dist = m.start(), abs(m.start() - gutter)
        if best_dist is not None:
            return best_start
    return gutter


STOCK_INTRO_TAIL_RE = re.compile(
    r'Bu hi Bible|bung \d{1,3}.{0,15}ch.ng \d{1,4} a awm|Bible a lehkhabu \d{1,3}-na'
)


def split_page_columns(
    page_text: str, hint: float | None = None
) -> tuple[list[str] | None, list[str] | None, str]:
    """Returns (left_lines, right_lines, strategy). Tries the whole page
    first; book-opener pages mix single-column intro prose with two-column
    verse text, which can defeat whole-page gutter detection, so falls back
    to progressively smaller bottom slices (the intro is always at the top).
    `hint` is this book's consensus gutter column (see extract_book),
    passed straight through to every find_gutter call so an ambiguous page
    resolves against the rest of the book instead of guessing alone."""
    lines = page_text.split("\n")
    gutter = find_gutter(lines, hint)
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
        gutter = find_gutter(sub, hint)
        if gutter is not None:
            left, right = [], []
            for l in sub:
                split_at = local_split_point(l, gutter)
                left.append(l[:split_at].rstrip())
                right.append(l[split_at:].rstrip())
            # Every book's intro ends with a stock sentence giving its
            # position and size. Three different wordings of it were found
            # directly: "X Bu hi Bible bu N-na a ni a..." ("X is Bible's
            # Nth book...", Genesis, Ezekiel, 1 Kings), "bung N ... ch{?}ng
            # N a awm" ("...has N chapters ... N verses", found with two
            # different conjunctions joining the two counts -- "bung 40
            # leh chhâng 1213 a awm" for Exodus/Leviticus/Judges, "bung 34
            # a awm a, chhâng 958 a awm bawk" for Deuteronomy -- hence the
            # loose gap between them rather than a fixed "leh"; the {?} is
            # a single placeholder char that decodes differently per font
            # subset, same reason _ABBR_LETTER includes the Unicode
            # replacement character), and "X hi Bible a lehkhabu N-na"
            # (the epistles' own phrasing for the same "Bible's Nth
            # letter" fact -- 2 Samuel, 1 Peter, 1/2 John, Revelation;
            # found directly on 2 John's single page, where this sentence
            # sits just 4 lines into the accepted skip and leaked straight
            # into English verse 1's text).
            # When the book's own Mizo name starts with a digit ("1
            # Lalte" for 1 Kings, and every other numbered book), THIS
            # line starts with a bare "1" too, which the minimal-skip
            # search above happily accepts as if it were verse 1 -- found
            # directly: it broke 1 Kings specifically this way, and the
            # verse-count sentence similarly leaked a fake "verse 1" into
            # Exodus. A gutter existing doesn't by itself mean the intro
            # has ended, so a candidate still containing either stock
            # phrase is rejected in favour of a larger skip, rather than
            # trusted just because some two-column structure was
            # detectable. Checked against the RAW pre-split lines, not
            # `left` -- found directly: Exodus's stock sentence straddles
            # exactly where this candidate's (wrong) gutter guess lands,
            # so it reads intact in `sub` but comes out cut in half across
            # `left`/`right`, invisible to either one alone.
            if not any(STOCK_INTRO_TAIL_RE.search(l) for l in sub[:10]):
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

        # A standalone chapter-title line ("SAM 2" / "PSALM 2"), checked
        # before everything else: it doesn't start with a digit, so it
        # can't collide with the verse regex or is_reference, but left
        # unhandled it would otherwise just get silently absorbed as
        # continuation text onto the PREVIOUS verse.
        m_title = CHAPTER_TITLE_RE.match(line)
        if m_title and int(m_title.group(1)) == self.chapter + 1:
            self.chapter, self.verse = int(m_title.group(1)), 0
            self.cur_key = None
            return

        m_selah = SELAH_LEAD_RE.match(line)
        if m_selah:
            if self.cur_key:
                self.verses[self.cur_key] = join_wrapped(self.verses[self.cur_key], "Selah")
            line = line[m_selah.end():]

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
            num, text = int(m.group(1)), m.group(2)
            if not self._would_accept(num):
                # A multi-digit chapter/verse marker can be typeset with an
                # internal space (found directly: Exodus 17 rendered as
                # "1 7 Then all the congregation..."). Only merges the next
                # short digit run onto `num` when doing so produces a
                # number that DOES satisfy the strict rule below -- this
                # never guesses blindly, it only resolves an otherwise
                # certain rejection.
                m2 = re.match(r'^(\d{1,2})[.\s]\s*(.*)$', text)
                if m2:
                    merged = int(f"{num}{m2.group(1)}")
                    if merged <= MAX_VERSE and self._would_accept(merged):
                        num, text = merged, m2.group(2)
            # The text itself can end with the NEXT verse's own marker --
            # found directly, Leviticus 7:28's whole line is "28 ... 28
            # Then the LORD spoke to Moses, saying, 29" (both sides open
            # verse 28 AND close with verse 29's marker on the same row).
            # VERSE_RE only ever looks at the START of a line, so without
            # this, the trailing "29" is silently swallowed into verse
            # 28's own text and never becomes a verse at all -- the same
            # cascading loss every other missed marker causes. Same
            # guards as the trailing-marker check below, but against
            # `num + 1` directly rather than _would_accept: `self.verse`
            # hasn't been updated to `num` yet at this point, so comparing
            # against the OLD verse number would be wrong.
            m_tail = TRAILING_MARKER_RE.match(text)
            if (
                m_tail
                and int(m_tail.group(2)) == num + 1
                and not is_reference(text[m_tail.start(2):])
                and not REF_CHAIN_TAIL_RE.search(m_tail.group(1))
                and (
                    m_tail.group(3) is None
                    or m_tail.group(3)[:1].isupper()
                    or m_tail.group(1)[-1:] in ';:,.'
                )
            ):
                self._start_verse(num, m_tail.group(1))
                self._start_verse(num + 1, m_tail.group(3) or "")
                return
            self._start_verse(num, text)
            return

        m_trail = TRAILING_MARKER_RE.match(line)
        trail_num = trail_g1 = None
        if m_trail:
            trail_num, trail_g1 = int(m_trail.group(2)), m_trail.group(1)
            if not self._would_accept(trail_num):
                # Multi-digit marker split across a gap, mirroring the
                # merge the leading-marker case already does -- found
                # directly, Jeremiah 34:16's own closing line is "...Ex.
                # 20:7 1  7": verse 17's marker, typeset as "1" then "7"
                # with a reference sitting right where the two digits of
                # "17" would otherwise be adjacent. Only merges when doing
                # so produces a number that DOES satisfy the strict rule
                # below -- never guesses blindly, same as the other merge.
                m2 = re.search(r'(?:^|\s)(\d{1,2})$', trail_g1)
                if m2:
                    merged = int(f"{m2.group(1)}{trail_num}")
                    if merged <= MAX_VERSE and self._would_accept(merged):
                        trail_num, trail_g1 = merged, trail_g1[:m2.start()].rstrip()
        if (
            m_trail
            and self.cur_key
            and self._would_accept(trail_num)
            # A numbered-book reference ("2 Lal. 4:8") starts with exactly
            # the same shape as a trailing marker with inline text, and
            # _would_accept alone doesn't catch it if the book number
            # happens to equal the real next verse (found directly: "...
            # Jos. 15:35; 2 Lal. 4:8" with the current verse genuinely
            # about to become 2). Checking whether the tail from the
            # marker onward is ITSELF a complete reference is what tells
            # the two apart -- if so, this isn't a new verse at all, and
            # it's left to fall through to plain continuation, where the
            # existing strip_trailing_refs cleans it up same as always.
            and not is_reference(line[m_trail.start(2):])
            and not REF_CHAIN_TAIL_RE.search(trail_g1)
            # A lowercase tail is trusted only right after real punctuation
            # (a clause boundary) -- found directly: Joshua 15:32's "...
            # khawpui 16 leh a khawperte n>n;" ("16 cities with their
            # villages") has its OWN number sitting mid-sentence, with
            # "16" happening to equal chapter+1 and no capital letter
            # after it either, same shape as Numbers 4:36's genuine
            # lowercase-continuation marker. The difference is what comes
            # right before the number: 4:36 follows "...meeting;", a real
            # clause break; Joshua's follows the ordinary word "khawpui",
            # no punctuation at all. A capitalized tail skips this check
            # entirely -- it was never the source of that false positive.
            and (
                m_trail.group(3) is None
                or m_trail.group(3)[:1].isupper()
                or trail_g1[-1:] in ';:,.'
            )
        ):
            # The text before the marker finishes the CURRENT verse; the
            # marker opens the next one. group(3), if present, is that new
            # verse's own text already sitting on this same line (short
            # verses running together inline) -- otherwise it has none yet,
            # and continuation lines that follow fill it in normally.
            self.verses[self.cur_key] = join_wrapped(self.verses[self.cur_key], trail_g1)
            self._start_verse(trail_num, m_trail.group(3) or "")
            return

        if self.cur_key:
            self.verses[self.cur_key] = join_wrapped(self.verses[self.cur_key], line)
        else:
            self.pending_heading_lines.append(line)

    def _would_accept(self, num: int) -> bool:
        """Read-only mirror of _start_verse's acceptance rule, used to test
        a candidate number (e.g. a merged split-digit marker) before
        committing to it, without duplicating or running the real state
        transition."""
        if self.chapter == 0:
            return True
        return num == self.verse + 1 or num == self.chapter + 1

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

    # Strip headers once and bank each page's own (hint-less) gutter guess,
    # then take the book's consensus (median) as a hint for the real pass
    # below. Every page in a book is printed with the one same fixed
    # column layout, so where most pages agree is strong independent
    # evidence for a page whose own text is too sparse to pin the gutter
    # down alone (found directly: Psalm 119's short, choppy lines left
    # enough stray blank space that the wrong column run was the widest).
    stripped_pages = []
    gutter_votes = []
    for page_text in pages:
        page_text, header = strip_header_line(page_text)
        stripped_pages.append((page_text, header))
        g = find_gutter(page_text.split("\n"))
        if g is not None:
            gutter_votes.append(g)
    hint = statistics.median(gutter_votes) if gutter_votes else None

    for i, (page_text, header) in enumerate(stripped_pages):
        pdf_page_num = first_page + i
        if header:
            headers.append((pdf_page_num, header))
        left_lines, right_lines, strategy = split_page_columns(page_text, hint)
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


def run_all() -> None:
    """Runs every book in BOOKS, prints one summary line each, and a final
    totals line. A clean row is 0 anomalies on both sides and a verse count
    matching between languages -- exactly the bar Genesis was held to."""
    grand_mizo = grand_eng = 0
    trouble: list[str] = []
    print(f"{'Book':<16} {'Ch':>4} {'Mizo v':>7} {'Eng v':>7} {'Anomalies':>10}  Status")
    print("-" * 64)
    for canonical_id, osis, name, chapter_count, first_page, last_page in BOOKS:
        mizo, eng, _, _, _, _ = extract_book(
            canonical_id, osis, name, chapter_count, first_page, last_page
        )
        n_anom = len(mizo.anomalies) + len(eng.anomalies)
        clean = (
            n_anom == 0
            and mizo.chapter == chapter_count
            and eng.chapter == chapter_count
            and len(mizo.verses) == len(eng.verses)
        )
        status = "OK" if clean else "CHECK"
        if not clean:
            trouble.append(name)
        print(
            f"{name:<16} {chapter_count:>4} {len(mizo.verses):>7} {len(eng.verses):>7} "
            f"{n_anom:>10}  {status}"
        )
        grand_mizo += len(mizo.verses)
        grand_eng += len(eng.verses)

    print("-" * 64)
    print(f"{'TOTAL':<16} {'':>4} {grand_mizo:>7} {grand_eng:>7}")
    print()
    if trouble:
        print(f"Needs a closer look ({len(trouble)}): {', '.join(trouble)}")
    else:
        print("All 66 books clean: zero anomalies, exact chapter and verse-count match.")


def main():
    # Windows' default console codepage (cp1252) can't print the Mizo
    # diacritics; force UTF-8 regardless of platform rather than relying on
    # PYTHONIOENCODING being set in the caller's shell.
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

    ap = argparse.ArgumentParser()
    ap.add_argument("--book", default="genesis")
    ap.add_argument("--json", default=None)
    ap.add_argument("--all", action="store_true", help="run every book, print a summary table")
    args = ap.parse_args()

    if args.all:
        run_all()
        return

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
