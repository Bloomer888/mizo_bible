import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizo_bible/app.dart';
import 'package:mizo_bible/core/db/bible_database.dart';
import 'package:mizo_bible/core/db/user_database.dart';

void main() {
  // The real bibleDatabaseProvider opens the bundled asset via
  // path_provider, which needs a platform channel plain `flutter_test`
  // doesn't mock -- overridden here with the small, real, committed
  // fixture (test/fixtures/bible_test.db) instead. userDatabaseProvider
  // is overridden too, with a fresh in-memory database per pump: left
  // alone, drift_flutter's driftDatabase() resolves to the same on-disk
  // file across both tests below, and Drift warns loudly about two live
  // UserDatabase instances sharing one file (real race-condition risk,
  // not just noise) -- each test gets its own isolated database instead.
  ProviderScope testScope() => ProviderScope(
        overrides: [
          bibleDatabaseProvider.overrideWith((ref) {
            final db = BibleDatabase(NativeDatabase(File('test/fixtures/bible_test.db')));
            ref.onDispose(db.close);
            return db;
          }),
          userDatabaseProvider.overrideWith((ref) {
            final db = UserDatabase(NativeDatabase.memory());
            ref.onDispose(db.close);
            return db;
          }),
        ],
        child: const MizoBibleApp(),
      );

  testWidgets('app starts and shows Genesis from the Bible database', (tester) async {
    await tester.pumpWidget(testScope());
    await tester.pumpAndSettle();

    expect(find.text('Genesis'), findsOneWidget);
    expect(find.textContaining('In the beginning God created'), findsOneWidget);
    expect(find.textContaining('A tîrah Pathianin'), findsOneWidget);
  });

  testWidgets('renders the Mizo alphabet without falling back', (tester) async {
    await tester.pumpWidget(testScope());
    await tester.pumpAndSettle();

    // U+1E6D is the character most likely to break on a device whose default
    // font lacks Latin Extended Additional coverage. Genesis 1:4's Mizo text
    // carries it naturally ("ṭha", "ṭhen").
    expect(find.textContaining('ṭ'), findsOneWidget);
  });
}
