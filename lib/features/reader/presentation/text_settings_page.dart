import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart' hide Table;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/bible_database.dart';
import '../../../core/l10n_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../data/reader_repository.dart' show defaultReaderSides;
import 'reader_settings.dart';

String _fontStyleLabel(AppLocalizations l10n, ReaderFontFamily style) => switch (style) {
      ReaderFontFamily.sans => l10n.fontStyleSans,
      ReaderFontFamily.sansCondensed => l10n.fontStyleSansCondensed,
      ReaderFontFamily.serif => l10n.fontStyleSerif,
      ReaderFontFamily.serifCondensed => l10n.fontStyleSerifCondensed,
    };

/// John 3:16, English side only -- already one of verse_of_the_day.dart's
/// curated references (bookId 43, chapter 3, verse 16), so already
/// confirmed present in bible.db under both translations before this ever
/// queries it. English only, not parallel: this card previews font size/
/// style/line-height, which is what the user asked it to do -- reading
/// mode and side-swap already have their own live controls right above it
/// on this same page.
final _previewVerseProvider = FutureProvider.autoDispose<String?>((ref) async {
  final db = ref.watch(bibleDatabaseProvider);
  final row = await (db.select(db.verses)
        ..where(
          (v) =>
              v.bookId.equals(43) &
              v.chapter.equals(3) &
              v.verse.equals(16) &
              v.translationId.equals(defaultReaderSides.bTranslationId),
        ))
      .getSingleOrNull();
  return row?.verseText;
});

/// Text Settings as a full page -- replaces the modal bottom sheet
/// (reader_settings_sheet.dart, deleted) the user's explicit call, so
/// there's room for the font-size slider's big-number/min-max layout and a
/// live preview, neither of which fit comfortably in a sheet. Reached from
/// both More and the reader's own Tt app bar button -- one page, not two
/// divergent UIs for the same settings.
class TextSettingsPage extends ConsumerWidget {
  const TextSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(readerSettingsProvider);
    final notifier = ref.read(readerSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.textSettings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Heading(l10n.fontSize),
          const SizedBox(height: 12),
          _FontSizeCard(fontSize: settings.fontSize, onChanged: notifier.setFontSize),
          const SizedBox(height: 24),
          _ScaleRow(
            icon: Icons.format_line_spacing,
            label: '${(settings.lineHeightScale * 100).round()}%',
            onDecrease: notifier.decreaseLineHeight,
            onIncrease: notifier.increaseLineHeight,
          ),
          const SizedBox(height: 24),
          // A dropdown, not a SegmentedButton -- four styles is one too
          // many to read comfortably as a row of segments on a phone
          // width. Each entry's labelWidget renders in the actual style
          // it selects, label stays plain text for the closed field and
          // for accessibility.
          DropdownMenu<ReaderFontFamily>(
            initialSelection: settings.fontFamily,
            label: Text(l10n.fontStyle),
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: [
              for (final style in ReaderFontFamily.values)
                DropdownMenuEntry(
                  value: style,
                  label: _fontStyleLabel(l10n, style),
                  labelWidget: Text(
                    _fontStyleLabel(l10n, style),
                    style: TextStyle(
                      fontFamily: style.familyName,
                      fontVariations: [FontVariation('wdth', style.width)],
                    ),
                  ),
                ),
            ],
            onSelected: (style) {
              if (style != null) notifier.setFontFamily(style);
            },
          ),
          const SizedBox(height: 16),
          SegmentedButton<ReadingMode>(
            segments: [
              ButtonSegment(value: ReadingMode.parallel, label: Text(l10n.readingModeParallel)),
              ButtonSegment(value: ReadingMode.mizoOnly, label: Text(l10n.readingModeMizoOnly)),
              ButtonSegment(value: ReadingMode.englishOnly, label: Text(l10n.readingModeEnglishOnly)),
            ],
            selected: {settings.mode},
            onSelectionChanged: (selection) => notifier.setMode(selection.first),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.swapLanguageSides),
            value: settings.swapped,
            onChanged: (_) => notifier.toggleSwap(),
          ),
          const SizedBox(height: 28),
          _Heading(l10n.preview),
          const SizedBox(height: 12),
          _PreviewCard(settings: settings),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.done),
            ),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.titleLarge ?? const TextStyle(fontSize: 20);
    return Text(text, style: AppTypography.weight(base, FontWeight.w700));
  }
}

/// The user's own reference screenshot: a big coloured number, a slider
/// with +/- buttons flanking it, min/max labels underneath. `divisions`
/// gives the Material 3 slider its small tick-dot track (matching that
/// screenshot's dotted look) and keeps every stop a whole point size.
class _FontSizeCard extends StatelessWidget {
  final double fontSize;
  final ValueChanged<double> onChanged;
  const _FontSizeCard({required this.fontSize, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Column(
          children: [
            Text(
              '${fontSize.round()}',
              style: AppTypography.weight(TextStyle(fontSize: 44, color: scheme.primary), FontWeight.w800),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: fontSize > minFontSize ? () => onChanged(fontSize - 1) : null,
                ),
                Expanded(
                  child: Slider(
                    value: fontSize,
                    min: minFontSize,
                    max: maxFontSize,
                    divisions: (maxFontSize - minFontSize).round(),
                    onChanged: onChanged,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: fontSize < maxFontSize ? () => onChanged(fontSize + 1) : null,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${minFontSize.round()}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  Text('${maxFontSize.round()}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// John 3:16 styled with exactly the font size/line-height/style the
/// controls above are currently set to -- not wrapped in reader_page.dart's
/// page-wide TextScaler, since this is one isolated piece of text, not
/// several differently-sized elements that need to stay proportional to
/// each other the way chapter headers and verse text do in the real reader.
class _PreviewCard extends ConsumerWidget {
  final ReaderSettings settings;
  const _PreviewCard({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verseAsync = ref.watch(_previewVerseProvider);
    final style = AppTypography.width(
      TextStyle(
        fontSize: settings.fontSize,
        height: settings.lineHeightScale,
        fontFamily: settings.fontFamily.familyName,
      ),
      settings.fontFamily.width,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: switch (verseAsync) {
          AsyncData(value: final text?) => Text(text, style: style),
          _ => const SizedBox(height: 48),
        },
      ),
    );
  }
}

class _ScaleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _ScaleRow({
    required this.icon,
    required this.label,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: onDecrease),
        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: onIncrease),
      ],
    );
  }
}
