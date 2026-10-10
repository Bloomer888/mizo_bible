import 'package:flutter/material.dart';

/// A verse-reference row used by the library list pages (bookmarks/
/// highlights/notes/history) and search results -- a Card instead of a
/// bare ListTile so each entry reads as a distinct, tappable item
/// instead of blending into one flat list.
class EntryCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const EntryCard({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A custom iconColor (e.g. a highlight's actual swatch) stays solid --
    // diluting it to the default 14%-alpha tint would wash out the one
    // piece of information it exists to show. Only the themed default
    // (no custom color -- bookmarks, notes, history, search) gets that tint.
    final solid = iconColor != null;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          radius: 19,
          backgroundColor: solid ? iconColor : scheme.primary.withValues(alpha: 0.14),
          child: Icon(icon, color: solid ? Colors.black54 : scheme.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Icon(Icons.chevron_right_rounded, color: scheme.outlineVariant),
        onTap: onTap,
      ),
    );
  }
}

/// Shared empty state for the library list pages and search -- an icon
/// above the message reads as considered design rather than a bare
/// "nothing here" string floating in the middle of the screen.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: scheme.outlineVariant),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
