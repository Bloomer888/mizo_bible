# Mizo Bible

Offline-first Mizo/English parallel Bible reader. Mizo and English side by
side, synchronised by verse, continuous scroll within a book. The Bible is
free and works with no account and no network.

## Running

Supabase credentials are passed at build time, not committed:

```bash
cp dart_define.example.json dart_define.json   # then fill in your values
flutter pub get
flutter gen-l10n
flutter run --dart-define-from-file=dart_define.json
```

The app starts and reads fine without `dart_define.json` — it just has no
sync or accounts, which is the intended offline behaviour.

## Common commands

```bash
flutter analyze                                   # must stay clean
flutter test
flutter gen-l10n                                  # after editing lib/l10n/*.arb
dart run build_runner build --delete-conflicting-outputs
                                                  # after changing a Drift table
                                                  # or a Riverpod provider
flutter build apk --release --dart-define-from-file=dart_define.json
```

## Layout

| Path | What |
|---|---|
| `lib/core/` | Database, text utilities, theme, build-time config |
| `lib/features/` | One folder per feature (reader, search, settings, …) |
| `lib/l10n/` | `.arb` translation files; English filled, Mizo later |
| `tool/` | `build_bible_db.py` — builds the shipped Bible database |
| `assets/db/` | Generated `bible.db` (gitignored, rebuild with the tool) |
| `assets/fonts/` | Noto Sans/Serif — needed for `ṭ` (U+1E6D) and circumflex vowels |
| `source_pdfs/` | Your Bible PDFs (gitignored, copyrighted) |

## Text and licensing

- **English: King James Version** — public domain.
- **Mizo: Pathian Lehkhabu Thianghlim, Common Language 1995** —
  © 1995 Bible Society of India, all rights reserved. **Written permission
  from BSI is required before publishing to any app store.** Translations are
  stored as data rows, so substituting a different Mizo text is a data change,
  not a code change.

## Fonts

Noto Sans and Noto Serif are bundled under the SIL Open Font License
(`assets/fonts/OFL.txt`). They are shipped rather than loaded from the system
because the Mizo alphabet needs `Ṭ`/`ṭ` (U+1E6C/U+1E6D) and circumflex vowels,
and Android's default font has incomplete coverage of that range.

These are **variable** fonts. Select weight through
`AppTypography.weight(...)` in `lib/core/theme/app_typography.dart`, not by
setting `fontWeight` alone — a single variable asset cannot be interpolated by
`fontWeight` and silently renders at the default weight.
