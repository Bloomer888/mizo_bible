import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizo_bible/app.dart';

void main() {
  testWidgets('app starts and shows its title', (tester) async {
    // MizoBibleApp is pumped directly rather than calling main(), so the test
    // never touches Supabase or the network.
    await tester.pumpWidget(const ProviderScope(child: MizoBibleApp()));
    await tester.pumpAndSettle();

    expect(find.text('Mizo Bible'), findsOneWidget);
  });

  testWidgets('renders the Mizo alphabet without falling back', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MizoBibleApp()));
    await tester.pumpAndSettle();

    // U+1E6D is the character most likely to break on a device whose default
    // font lacks Latin Extended Additional coverage.
    expect(find.textContaining('ṭ'), findsOneWidget);
  });
}
