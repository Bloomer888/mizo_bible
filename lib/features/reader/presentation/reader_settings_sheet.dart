import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_extension.dart';
import '../../../l10n/app_localizations.dart';
import 'reader_settings.dart';

String _fontStyleLabel(AppLocalizations l10n, ReaderFontFamily style) => switch (style) {
      ReaderFontFamily.sans => l10n.fontStyleSans,
      ReaderFontFamily.sansCondensed => l10n.fontStyleSansCondensed,
      ReaderFontFamily.serif => l10n.fontStyleSerif,
      ReaderFontFamily.serifCondensed => l10n.fontStyleSerifCondensed,
    };

class ReaderSettingsSheet extends ConsumerWidget {
  const ReaderSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readerSettingsProvider);
    final notifier = ref.read(readerSettingsProvider.notifier);
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.textSettings, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            _ScaleRow(
              icon: Icons.text_fields,
              label: '${(settings.fontScale * 100).round()}%',
              onDecrease: notifier.decreaseFontScale,
              onIncrease: notifier.increaseFontScale,
            ),
            const SizedBox(height: 12),
            _ScaleRow(
              icon: Icons.format_line_spacing,
              label: '${(settings.lineHeightScale * 100).round()}%',
              onDecrease: notifier.decreaseLineHeight,
              onIncrease: notifier.increaseLineHeight,
            ),
            const SizedBox(height: 20),
            // A dropdown, not a SegmentedButton -- four styles is one too
            // many to read comfortably as a row of segments on a phone
            // width, where the font-size/line-height rows and the (three-
            // segment) reading-mode row below still fit fine. Each entry's
            // labelWidget renders in the actual style it selects -- the
            // fastest possible preview, same idea as how other reading
            // apps' font pickers work -- while label stays plain text for
            // the closed field and for accessibility.
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
            const SizedBox(height: 12),
            SegmentedButton<ReadingMode>(
              segments: [
                ButtonSegment(value: ReadingMode.parallel, label: Text(l10n.readingModeParallel)),
                ButtonSegment(value: ReadingMode.mizoOnly, label: Text(l10n.readingModeMizoOnly)),
                ButtonSegment(value: ReadingMode.englishOnly, label: Text(l10n.readingModeEnglishOnly)),
              ],
              selected: {settings.mode},
              onSelectionChanged: (selection) => notifier.setMode(selection.first),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.swapLanguageSides),
              value: settings.swapped,
              onChanged: (_) => notifier.toggleSwap(),
            ),
          ],
        ),
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
