import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_extension.dart';
import 'reader_settings.dart';

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
            // Each segment's label renders in the font it switches to --
            // the fastest possible preview of what "Serif" actually looks
            // like, same idea as how other reading apps' font pickers work.
            SegmentedButton<ReaderFontFamily>(
              segments: [
                ButtonSegment(
                  value: ReaderFontFamily.sans,
                  label: Text(l10n.fontStyleSans, style: TextStyle(fontFamily: ReaderFontFamily.sans.familyName)),
                ),
                ButtonSegment(
                  value: ReaderFontFamily.serif,
                  label: Text(l10n.fontStyleSerif, style: TextStyle(fontFamily: ReaderFontFamily.serif.familyName)),
                ),
              ],
              selected: {settings.fontFamily},
              onSelectionChanged: (selection) => notifier.setFontFamily(selection.first),
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
