# Mizo Bible

Offline-first Mizo/English parallel Bible reader. Mizo and English side by
side, synchronised by verse, continuous scroll within a book. The Bible is
free and works with no account and no network.

## Running

Supabase and RevenueCat credentials are passed at build time, not committed:

```bash
cp dart_define.example.json dart_define.json   # then fill in your values
flutter pub get
flutter gen-l10n
flutter run --dart-define-from-file=dart_define.json
```

The app starts and reads fine without `dart_define.json` — it just has no
sync, accounts, or Premium, which is the intended offline behaviour.
`REVENUECAT_ANDROID_API_KEY` specifically can stay blank until a RevenueCat
project and Play Console in-app products both exist; every Premium surface
degrades to "unavailable" rather than erroring (see `Env.hasRevenueCat`).

## Common commands

```bash
flutter analyze                                   # must stay clean
flutter test
flutter gen-l10n                                  # after editing lib/l10n/*.arb
dart run build_runner build --delete-conflicting-outputs
                                                  # after changing a Drift table
                                                  # or a Riverpod provider
python tool/export_bible_db.py                    # regenerate assets/db/bible.db --
                                                  # always do this before a release
                                                  # build; it's gitignored, so a
                                                  # locally stale copy (e.g. predating
                                                  # a schema/FTS change) won't show up
                                                  # in any diff and can ship silently
                                                  # broken -- caught once already, when
                                                  # search had no verses_fts table
flutter build apk --release --dart-define-from-file=dart_define.json
```

## Layout

| Path | What |
|---|---|
| `lib/core/` | Database, text utilities, theme, build-time config |
| `lib/features/` | One folder per feature (reader, search, settings, …) |
| `lib/l10n/` | `.arb` translation files; English filled, Mizo later |
| `tool/` | PDF → `bible.db` pipeline: `extract_pdf.py`, `seed_supabase.py`, `export_bible_db.py` |
| `assets/db/` | Generated `bible.db` (gitignored, rebuild with the tool) |
| `assets/fonts/` | Noto Sans/Serif — needed for `ṭ` (U+1E6D) and circumflex vowels |
| `source_pdfs/` | Your Bible PDFs (gitignored, copyrighted) |
| `supabase/migrations/` | `content.*` (canonical Bible text, admin-only) and `user_data.*` (bookmarks/notes/etc., RLS-owned by each user) |

The Bible text is canonical in Supabase's `content.*` schema (admin-edited) and
exported per release into the bundled `bible.db` — the app itself only ever
reads the local file, never Supabase, for Bible text:

```
PDF --(extract_pdf.py)--> structured data --(seed_supabase.py)--> Supabase content.*
                                            --(export_bible_db.py, per release)--> assets/db/bible.db
```

## Text and licensing

- **Mizo**: Mizo-English Parallel Bible (2010/2011/2015/2017 revisions), a
  product of the Christian Research Centre, Aizawl — © Dr. P.C. Biaksiama,
  translator. **Rights confirmed** via the pastor, one of the named rights
  holders.
- **English**: King James Version blended with New King James Version, "used
  by permission of Thomas Nelson" per the source PDF's copyright page — not
  plain public-domain KJV. NKJV is administered today by HarperCollins
  Christian Publishing, whose gratis-use policy caps free quotation at 500
  verses / 25% of the work / 50% of any one book. Shipping the full text
  exceeds that, so this is tracked as **rights pending** (see
  `translations.rights_status` in `content.*`) — **written permission from
  HarperCollins Christian Publishing is required before wide release or any
  Premium billing.**

Translations are stored as data rows (`content.translations`), so
substituting or removing a text is a data change, not a code change.

## Fonts

Noto Sans and Noto Serif are bundled under the SIL Open Font License
(`assets/fonts/OFL.txt`). They are shipped rather than loaded from the system
because the Mizo alphabet needs `Ṭ`/`ṭ` (U+1E6C/U+1E6D) and circumflex vowels,
and Android's default font has incomplete coverage of that range.

These are **variable** fonts. Select weight through
`AppTypography.weight(...)` in `lib/core/theme/app_typography.dart`, not by
setting `fontWeight` alone — a single variable asset cannot be interpolated by
`fontWeight` and silently renders at the default weight.
