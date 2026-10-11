import 'package:flutter/material.dart';

import '../../../core/l10n_extension.dart';
import '../data/legal_text.dart';
import 'legal_text_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
            child: Column(
              children: [
                Text(l10n.appTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  'Dr. P.C. Biaksiama',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                // Keep in sync with pubspec.yaml's version -- no
                // package_info_plus dependency for one display line.
                const Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(l10n.bibleTextSectionTitle, style: Theme.of(context).textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(l10n.bibleTextRights),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.privacyPolicy),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LegalTextPage(title: l10n.privacyPolicy, body: privacyPolicyText),
              ),
            ),
          ),
          ListTile(
            title: Text(l10n.termsOfService),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LegalTextPage(title: l10n.termsOfService, body: termsOfServiceText),
              ),
            ),
          ),
          ListTile(
            title: Text(l10n.openSourceLicenses),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appTitle,
              applicationVersion: '1.0.0',
            ),
          ),
        ],
      ),
    );
  }
}
