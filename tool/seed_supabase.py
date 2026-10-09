#!/usr/bin/env python3
"""Stage 2 of the Phase 2 content pipeline: structured verse data -> Supabase.

Takes extract_pdf.py's output for all 66 books and pushes it into the
content.* schema (supabase/migrations/20261008133644_content_schema.sql).
Needs the service-role key (bypasses RLS) -- never the publishable key
already in dart_define.json, and never committed or hardcoded. Read from
environment variables only:

    SUPABASE_URL                 (same project as dart_define.json)
    SUPABASE_SERVICE_ROLE_KEY    (Dashboard -> Project Settings -> API)

Usage:
    python tool/seed_supabase.py --dry-run     # no network calls at all,
                                                # just prints row counts
    python tool/seed_supabase.py               # the real write

Seeds content.translations, content.books, content.book_names, and
content.verses. Deliberately does NOT touch content.parallel_rows yet --
that needs its own pass once this lands and is verified, same "one step
at a time" reasoning as the whole PDF-extraction phase.
"""

import argparse
import os
import sys
from pathlib import Path

import requests

sys.path.insert(0, str(Path(__file__).parent))
import extract_pdf as ep

TRANSLATIONS = [
    {
        "id": "mizo_crc_2026",
        "name": "Mizo-English Parallel Bible (Mizo text)",
        "short_name": "Mizo",
        "language_code": "lus",
        "year": 2026,
        "publisher": "Christian Research Centre, Aizawl",
        # Confirmed via the pastor's own authority -- see the plan's text
        # rights callout.
        "rights_status": "confirmed",
        "rights_notes": "Rights confirmed via the pastor, one of the named rights holders (Dr. P.C. Biaksiama, translator; Christian Research Centre, Aizawl).",
        "is_bundled": True,
        "sort_order": 0,
    },
    {
        "id": "kjv_nkjv_blend",
        "name": "King James Version with New King James Version",
        "short_name": "KJV/NKJV",
        "language_code": "en",
        "year": 2026,
        "publisher": "Thomas Nelson / HarperCollins Christian Publishing",
        # Still open -- see the plan's text rights callout. Tracked here,
        # not just in the planning doc, precisely so it has a permanent,
        # visible home.
        "rights_status": "pending",
        "rights_notes": (
            "Blended KJV/NKJV text, 'used by permission of Thomas Nelson' per "
            "the source PDF's copyright page. NKJV's gratis-use policy caps "
            "free quotation at 500 verses / 25% of a work / 50% of one book -- "
            "shipping the full text needs separate confirmation from "
            "HarperCollins Christian Publishing before wide release or "
            "Premium billing."
        ),
        "is_bundled": True,
        "sort_order": 1,
    },
]

# Books whose own header-derived name can't be trusted. 2 John and Jude
# never produced a header match at all (found directly from each book's
# own opener page title instead). Lamentations is different -- it DOES
# have one header "match", but it's spurious: "THUFINGTE 1:19" paired
# with "LAMENTATIONS 2:6" on the SAME row, mismatched on both book name
# and chapter:verse, the one and only header line recorded for the whole
# book. "Thufingte" is actually Proverbs' own name -- confirmed wrong,
# not just low-confidence, by checking every other book's header count
# for comparison. Lamentations' real Mizo name, "Ṭah Hla", is from its
# own opener page instead ("Ṭah Hla hi Bible-a bu 25-na a ni a...").
MIZO_NAME_OVERRIDES = {
    "Lamentations": "Ṭah Hla",
    "2 John": "2 Johana",
    "Jude": "Juda",
}


def mizo_book_name(name: str, headers: list[tuple[int, tuple]]) -> str:
    if name in MIZO_NAME_OVERRIDES:
        return MIZO_NAME_OVERRIDES[name]
    counts: dict[str, int] = {}
    for _, header in headers:
        counts[header[0]] = counts.get(header[0], 0) + 1
    if not counts:
        raise ValueError(f"no header-derived Mizo name for {name!r} and no override set")
    return max(counts, key=counts.get).title()


def build_rows():
    """Runs extract_book for all 66 books and returns the four row lists."""
    books_rows = []
    book_names_rows = []
    verses_rows = []

    for canonical_id, osis, name, chapter_count, first_page, last_page in ep.BOOKS:
        mizo, eng, _, mizo_stripped, eng_stripped, headers = ep.extract_book(
            canonical_id, osis, name, chapter_count, first_page, last_page
        )

        testament = "OT" if canonical_id <= 39 else "NT"
        books_rows.append(
            {
                "id": canonical_id,
                "testament": testament,
                "chapter_count": chapter_count,
                "osis_code": osis,
            }
        )

        mizo_name = mizo_book_name(name, headers)
        book_names_rows.append(
            {
                "book_id": canonical_id,
                "translation_id": "mizo_crc_2026",
                "name": mizo_name,
                "short_name": mizo_name,
            }
        )
        book_names_rows.append(
            {
                "book_id": canonical_id,
                "translation_id": "kjv_nkjv_blend",
                "name": name,
                "short_name": name,
            }
        )

        for col, translation_id in ((mizo, "mizo_crc_2026"), (eng, "kjv_nkjv_blend")):
            for (chapter, verse), text in col.verses.items():
                heading = col.headings.get((chapter, verse))
                refs = col.refs.get((chapter, verse))
                verses_rows.append(
                    {
                        "translation_id": translation_id,
                        "book_id": canonical_id,
                        "chapter": chapter,
                        "verse": verse,
                        "text": text,
                        "heading": heading,
                        "cross_ref": "; ".join(refs) if refs else None,
                    }
                )

    return books_rows, book_names_rows, verses_rows


def post_batch(session: requests.Session, base_url: str, table: str, rows: list[dict]) -> None:
    """Upserts `rows` into content.{table} in batches of 500."""
    url = f"{base_url}/rest/v1/{table}"
    batch_size = 500
    for i in range(0, len(rows), batch_size):
        batch = rows[i : i + batch_size]
        resp = session.post(url, json=batch)
        if resp.status_code not in (200, 201, 204):
            raise RuntimeError(
                f"POST {table} batch {i}-{i + len(batch)} failed: "
                f"{resp.status_code} {resp.text[:500]}"
            )
        print(f"  {table}: wrote rows {i}-{i + len(batch)} of {len(rows)}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--dry-run",
        action="store_true",
        help="build and summarize the data only, no network calls at all",
    )
    args = ap.parse_args()

    sys.stdout.reconfigure(encoding="utf-8")

    print("Extracting all 66 books (this re-runs the full PDF extraction)...")
    books_rows, book_names_rows, verses_rows = build_rows()

    print()
    print("Row counts:")
    print(f"  content.translations: {len(TRANSLATIONS)}")
    print(f"  content.books:        {len(books_rows)}")
    print(f"  content.book_names:   {len(book_names_rows)}")
    print(f"  content.verses:       {len(verses_rows)}")
    mizo_n = sum(1 for r in verses_rows if r["translation_id"] == "mizo_crc_2026")
    eng_n = sum(1 for r in verses_rows if r["translation_id"] == "kjv_nkjv_blend")
    print(f"    (Mizo: {mizo_n}, English: {eng_n})")

    if args.dry_run:
        print()
        print("Dry run -- no network calls made. Sample rows:")
        print("  books[0]:", books_rows[0])
        print("  book_names[0:2]:", book_names_rows[0:2])
        print("  verses[0]:", verses_rows[0])
        return

    base_url = os.environ.get("SUPABASE_URL")
    service_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if not base_url or not service_key:
        print(
            "ERROR: set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment "
            "variables first (service-role key, from Dashboard -> Project "
            "Settings -> API -- never the publishable key, never committed).",
            file=sys.stderr,
        )
        sys.exit(1)

    session = requests.Session()
    session.headers.update(
        {
            "apikey": service_key,
            "Authorization": f"Bearer {service_key}",
            "Content-Type": "application/json",
            "Prefer": "resolution=merge-duplicates,return=minimal",
        }
    )

    print()
    print("Writing to Supabase...")
    post_batch(session, base_url, "translations", TRANSLATIONS)
    post_batch(session, base_url, "books", books_rows)
    post_batch(session, base_url, "book_names", book_names_rows)
    post_batch(session, base_url, "verses", verses_rows)
    print()
    print("Done.")


if __name__ == "__main__":
    main()
