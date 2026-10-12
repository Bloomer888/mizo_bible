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

  // pump() with an explicit settle duration, not pumpAndSettle() --
  // Home's streak card (app_shell.dart's IndexedStack keeps every tab
  // mounted regardless of which one is visible) runs two deliberately
  // infinite animations (the flickering flame, and the check-in
  // circle's inviting pulse while today isn't marked yet), so
  // pumpAndSettle would wait forever for frames that never stop being
  // scheduled. 500ms is comfortably past both tabs' own async provider
  // chains resolving (bible.db query, the in-memory user db), without
  // needing to wait out either animation's own loop.
  Future<void> pumpAndLoad(WidgetTester tester) async {
    await tester.pumpWidget(testScope());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('app starts and shows Genesis from the Bible database', (tester) async {
    await pumpAndLoad(tester);

    // At least one, not exactly one: the book/chapter/verse picker's own
    // field also displays the current book's name now, alongside the
    // app bar title -- both showing "Genesis" is correct, not a dupe bug.
    expect(find.text('Genesis'), findsAtLeastNWidgets(1));
    expect(find.textContaining('In the beginning God created'), findsOneWidget);
    expect(find.textContaining('A tîrah Pathianin'), findsOneWidget);
  });

  testWidgets('renders the Mizo alphabet without falling back', (tester) async {
    await pumpAndLoad(tester);

    // U+1E6D is the character most likely to break on a device whose default
    // font lacks Latin Extended Additional coverage. Genesis 1:4's Mizo text
    // carries it naturally ("ṭha", "ṭhen").
    expect(find.textContaining('ṭ'), findsOneWidget);
  });
}
