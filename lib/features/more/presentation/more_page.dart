import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_extension.dart';
import '../../about/presentation/about_page.dart';
import '../../auth/presentation/account_page.dart';
import '../../library/presentation/bookmarks_page.dart';
import '../../library/presentation/highlights_page.dart';
import '../../library/presentation/notes_page.dart';
import '../../premium/data/premium_providers.dart';
import '../../premium/presentation/paywall_page.dart';
import '../../reader/presentation/reader_settings_sheet.dart';
import '../../reading_plans/presentation/reading_plans_page.dart';

/// The More tab -- everything that isn't "read the Bible right now":
/// the library views, reading preferences, account, and the legal/
/// about screens. Replaces the reader's old hamburger drawer, which
/// had the same job but only while a book happened to be on screen.
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isPremium = ref.watch(isPremiumProvider);

    void openPage(Widget page) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.more)),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.workspace_premium_rounded, color: Theme.of(context).colorScheme.primary),
            title: Text(isPremium ? l10n.premium : l10n.upgradeToPremium),
            onTap: () => openPage(const PaywallPage()),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_rounded),
            title: Text(l10n.readingPlans),
            // Not Premium -> same destination as tapping "Upgrade to
            // Premium" itself, consistent with how this app gates its
            // one other Premium feature (sync): the paywall is the
            // single place that ever prompts for it, never a dead end
            // or a disabled-looking row.
            onTap: () => openPage(isPremium ? const ReadingPlansPage() : const PaywallPage()),
          ),
          const Divider(indent: 16, endIndent: 16),
          _SectionLabel(l10n.yourBible),
          ListTile(
            leading: const Icon(Icons.bookmark_rounded),
            title: Text(l10n.bookmarks),
            onTap: () => openPage(const BookmarksPage()),
          ),
          ListTile(
            leading: const Icon(Icons.format_color_fill_rounded),
            title: Text(l10n.highlights),
            onTap: () => openPage(const HighlightsPage()),
          ),
          ListTile(
            leading: const Icon(Icons.edit_note_rounded),
            title: Text(l10n.notes),
            onTap: () => openPage(const NotesPage()),
          ),
          const Divider(indent: 16, endIndent: 16),
          _SectionLabel(l10n.settings),
          ListTile(
            leading: const Icon(Icons.text_fields_rounded),
            title: Text(l10n.textSettings),
            onTap: () => showModalBottomSheet(
              context: context,
              builder: (_) => const ReaderSettingsSheet(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle_rounded),
            title: Text(l10n.account),
            onTap: () => openPage(const AccountPage()),
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: Text(l10n.about),
            onTap: () => openPage(const AboutPage()),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
