#!/usr/bin/env python3
"""Stage 3 of the Phase 2 content pipeline: Supabase content.* -> bible.db.

Run this per release (after any admin-panel edits land in Supabase). Reads
content.translations/books/book_names/verses via PostgREST -- same
service-role credentials as seed_supabase.py, read from environment
variables only:

    SUPABASE_URL
    SUPABASE_SERVICE_ROLE_KEY

Writes assets/db/bible.db, the read-only SQLite file the Flutter app bundles
and queries at runtime. The app never talks to Supabase directly for Bible
text -- this script is the only bridge.

content.parallel_rows is still unpopulated in Supabase (seed_supabase.py
deliberately left it for its own later pass), so this script SYNTHESIZES a
simple 1-to-1 parallel_rows table locally, pairing verse N on one side with
verse N on the other for every chapter. Phase 1 found this is a
professionally typeset parallel Bible where both sides mostly share the same
versification, so this is a reasonable placeholder -- not a guess pulled
from nowhere -- but it is still a placeholder: a verse present on only one
side (the Mizo/English verse counts already differ by 14) ends up a
one-sided row (null on the missing side) rather than a verified merge/split
alignment. Replace this function with real alignment logic once that pass
happens; nothing else in this script should need to change.

Usage:
    python tool/export_bible_db.py
"""

import os
import sqlite3
import sys
from pathlib import Path

import requests

sys.path.insert(0, str(Path(__file__).parent))
from fold import fold_for_search

BASE_DIR = Path(__file__).parent.parent
DB_PATH = BASE_DIR / "assets" / "db" / "bible.db"

PAGE_SIZE = 1000


def fetch_all(session: requests.Session, base_url: str, table: str, select: str, order: str) -> list[dict]:
    """GETs every row of content.{table}, paging past the project's max-rows cap."""
    url = f"{base_url}/rest/v1/{table}"
    rows: list[dict] = []
    offset = 0
    while True:
        resp = session.get(
            url,
            params={"select": select, "order": order, "limit": PAGE_SIZE, "offset": offset},
        )
        if resp.status_code != 200:
            raise RuntimeError(f"GET {table} offset {offset} failed: {resp.status_code} {resp.text[:500]}")
        batch = resp.json()
        rows.extend(batch)
        print(f"  {table}: fetched {len(rows)}")
        if len(batch) < PAGE_SIZE:
            return rows
        offset += PAGE_SIZE


MIZO_ID = "mizo_crc_2026"
ENGLISH_ID = "kjv_nkjv_blend"
PAIR_ID = f"{MIZO_ID}|{ENGLISH_ID}"


def synthesize_parallel_rows(verses_rows: list[dict]) -> list[tuple]:
    """1-to-1 verse-number pairing per (book, chapter) -- see module docstring."""
    by_book_chapter: dict[tuple[int, int], dict[str, set[int]]] = {}
    for row in verses_rows:
        key = (row["book_id"], row["chapter"])
        slot = by_book_chapter.setdefault(key, {MIZO_ID: set(), ENGLISH_ID: set()})
        slot[row["translation_id"]].add(row["verse"])

    out = []
    for (book_id, chapter), sides in sorted(by_book_chapter.items()):
        all_verses = sorted(sides[MIZO_ID] | sides[ENGLISH_ID])
        for row_index, verse in enumerate(all_verses):
            a = verse if verse in sides[MIZO_ID] else None
            b = verse if verse in sides[ENGLISH_ID] else None
            out.append((PAIR_ID, book_id, chapter, row_index, str(verse), a, a, b, b))
    return out


SCHEMA = """
create table translations (
    id             text primary key,
    name           text not null,
    short_name     text not null,
    language_code  text not null,
    year           integer,
    publisher      text,
    rights_status  text not null,
    rights_notes   text,
    license_text   text,
    sort_order     integer not null
);

create table books (
    id             integer primary key,
    testament      text not null,
    chapter_count  integer not null,
    osis_code      text not null
);

create table book_names (
    book_id        integer not null references books(id),
    translation_id text not null references translations(id),
    name           text not null,
    short_name     text not null,
    primary key (book_id, translation_id)
);

create table verses (
    translation_id text not null references translations(id),
    book_id        integer not null references books(id),
    chapter        integer not null,
    verse          integer not null,
    text           text not null,
    text_folded    text not null,
    heading        text,
    cross_ref      text,
    primary key (translation_id, book_id, chapter, verse)
);
create index verses_book_chapter on verses (book_id, chapter, verse);

create table parallel_rows (
    pair_id    text not null,
    book_id    integer not null references books(id),
    chapter    integer not null,
    row_index  integer not null,
    label      text not null,
    a_start    integer,
    a_end      integer,
    b_start    integer,
    b_end      integer,
    primary key (pair_id, book_id, chapter, row_index)
);

-- External-content FTS5 index over the already-folded search column --
-- indexes text_folded, not text, so a query folded the same way (Dart:
-- foldForSearch, lib/core/text/fold.dart) matches regardless of case or
-- Mizo diacritics. content_rowid='rowid' relies on verses' own implicit
-- SQLite rowid (it isn't declared WITHOUT ROWID), populated below by
-- copying that same rowid across rather than inserting independently,
-- so the two tables' rows line up exactly.
create virtual table verses_fts using fts5(
    text_folded,
    content='verses',
    content_rowid='rowid'
);
"""


def build_db(translations, books, book_names, verses, parallel_rows) -> None:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    if DB_PATH.exists():
        DB_PATH.unlink()

    conn = sqlite3.connect(DB_PATH)
    conn.executescript(SCHEMA)

    conn.executemany(
        "insert into translations values (:id,:name,:short_name,:language_code,:year,:publisher,"
        ":rights_status,:rights_notes,:license_text,:sort_order)",
        translations,
    )
    conn.executemany(
        "insert into books values (:id,:testament,:chapter_count,:osis_code)",
        books,
    )
    conn.executemany(
        "insert into book_names values (:book_id,:translation_id,:name,:short_name)",
        book_names,
    )
    conn.executemany(
        "insert into verses values (:translation_id,:book_id,:chapter,:verse,:text,"
        ":text_folded,:heading,:cross_ref)",
        verses,
    )
    conn.executemany(
        "insert into parallel_rows values (?,?,?,?,?,?,?,?,?)",
        parallel_rows,
    )
    conn.execute("insert into verses_fts(rowid, text_folded) select rowid, text_folded from verses")

    # Tells Drift on open "this schema already exists, don't run onCreate"
    # -- must match BibleDatabase.schemaVersion in
    # lib/core/db/bible_database.dart, same cross-language-agreement
    # reasoning as fold.py/fold.dart.
    conn.execute("PRAGMA user_version = 1")

    conn.commit()
    conn.execute("vacuum")
    conn.close()


def main():
    sys.stdout.reconfigure(encoding="utf-8")

    base_url = os.environ.get("SUPABASE_URL")
    service_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if not base_url or not service_key:
        print(
            "ERROR: set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment "
            "variables first (service-role key, from Dashboard -> Project "
            "Settings -> API Keys -- never the publishable key, never committed).",
            file=sys.stderr,
        )
        sys.exit(1)

    session = requests.Session()
    session.headers.update(
        {
            "apikey": service_key,
            "Authorization": f"Bearer {service_key}",
            "Accept-Profile": "content",
        }
    )

    print("Fetching content.* from Supabase...")
    translations = fetch_all(session, base_url, "translations", "*", "sort_order")
    books = fetch_all(session, base_url, "books", "*", "id")
    book_names = fetch_all(session, base_url, "book_names", "*", "book_id,translation_id")
    verses = fetch_all(session, base_url, "verses", "*", "book_id,chapter,verse,translation_id")
    for v in verses:
        v["text_folded"] = fold_for_search(v["text"])

    print()
    print("Synthesizing parallel_rows (1-to-1 placeholder -- see module docstring)...")
    parallel_rows = synthesize_parallel_rows(verses)
    print(f"  parallel_rows: {len(parallel_rows)} rows")

    print()
    print(f"Writing {DB_PATH}...")
    build_db(translations, books, book_names, verses, parallel_rows)
    size_mb = DB_PATH.stat().st_size / (1024 * 1024)
    print(f"Done. {DB_PATH} ({size_mb:.1f} MB)")


if __name__ == "__main__":
    main()
