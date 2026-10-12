-- Defense-in-depth on top of the RLS already in place
-- (20261010090000_user_data_schema.sql, 20261011190635_reading_plan_progress.sql).
-- RLS already stops a signed-in user from touching anyone else's rows --
-- these constraints stop a signed-in user (or a client that's been
-- tampered with/bypassed entirely, talking straight to the Data API)
-- from writing nonsense or oversized data into their OWN rows, which
-- RLS alone has no opinion on. Written as a separate migration rather
-- than edited into the two above, since both may already be applied --
-- ALTER TABLE here works whether this runs right after them in the same
-- push or against tables that have existed for a while.
--
-- Ranges are generous on purpose: 1..150 for chapter (Psalms, the
-- longest book) and 1..176 for verse (Psalm 119, the longest chapter)
-- cover every real reference with room to spare, while still rejecting
-- obvious garbage (book_id -1, chapter 999999, etc).

alter table user_data.bookmarks
  add constraint bookmarks_book_id_range check (book_id between 1 and 66),
  add constraint bookmarks_chapter_range check (chapter between 1 and 150),
  add constraint bookmarks_verse_range check (verse between 1 and 176);

alter table user_data.highlights
  add constraint highlights_book_id_range check (book_id between 1 and 66),
  add constraint highlights_chapter_range check (chapter between 1 and 150),
  add constraint highlights_verse_range check (verse between 1 and 176),
  -- Keep this list in sync with highlightColors in
  -- lib/features/reader/presentation/verse_actions_sheet.dart -- same
  -- reasoning as content.translations.rights_status's own enum check.
  add constraint highlights_color_enum check (color in ('yellow', 'green', 'blue', 'pink', 'orange'));

alter table user_data.notes
  add constraint notes_book_id_range check (book_id between 1 and 66),
  add constraint notes_chapter_range check (chapter between 1 and 150),
  add constraint notes_verse_range check (verse between 1 and 176),
  -- Generous for a verse note -- nothing in the app's UI approaches this.
  add constraint notes_content_length check (char_length(content) <= 10000);

alter table user_data.reading_progress
  add constraint reading_progress_book_id_range check (book_id between 1 and 66),
  add constraint reading_progress_chapter_range check (chapter between 1 and 150),
  add constraint reading_progress_verse_range check (verse between 1 and 176);

alter table user_data.settings
  -- reader_settings' JSON blob and book_name_language are both tiny;
  -- this caps any key's value generously rather than per-key.
  add constraint settings_value_length check (char_length(value) <= 10000);

alter table user_data.reading_plan_progress
  -- "1,2,...,90" for the current 90-day plan is ~260 chars; this leaves
  -- room for a future year-long plan without being unbounded.
  add constraint reading_plan_progress_csv_length check (char_length(completed_days_csv) <= 2000);

-- Explicit, not relying on "we just never granted it" by omission --
-- anon has no auth.uid() to satisfy any policy here anyway (anonymous
-- auth is disabled project-wide), so this changes nothing functionally,
-- but makes the authenticated-only intent bulletproof against a future
-- migration accidentally widening it.
revoke all on schema user_data from anon;
revoke all on all tables in schema user_data from anon;
