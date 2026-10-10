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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Column(
              children: [
                Text('Mizo Bible', style: TextStyle(fontSize: 20)),
                SizedBox(height: 4),
                // Keep in sync with pubspec.yaml's version -- no
                // package_info_plus dependency for one display line.
                Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
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
              applicationName: 'Mizo Bible',
              applicationVersion: '1.0.0',
            ),
          ),
        ],
      ),
    );
  }
}
