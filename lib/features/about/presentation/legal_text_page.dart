import 'package:flutter/material.dart';

/// A plain scrollable text page -- shared by the Privacy Policy and
/// Terms of Service screens, which are otherwise identical in shape.
class LegalTextPage extends StatelessWidget {
  final String title;
  final String body;

  const LegalTextPage({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Text(body, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
