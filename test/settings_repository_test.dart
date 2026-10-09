import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizo_bible/core/db/settings_repository.dart';
import 'package:mizo_bible/core/db/user_database.dart';

void main() {
  late UserDatabase db;

  setUp(() => db = UserDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('unset key loads as null', () async {
    expect(await loadSetting(db, 'nope'), isNull);
  });

  test('saves and loads a value', () async {
    await saveSetting(db, 'theme', 'dark');
    expect(await loadSetting(db, 'theme'), 'dark');
  });

  test('saving again for the same key updates in place rather than duplicating', () async {
    await saveSetting(db, 'theme', 'dark');
    await saveSetting(db, 'theme', 'light');

    final rows = await db.select(db.settings).get();
    expect(rows, hasLength(1));
    expect(await loadSetting(db, 'theme'), 'light');
  });

  test('different keys are independent', () async {
    await saveSetting(db, 'theme', 'dark');
    await saveSetting(db, 'font_scale', '1.2');

    expect(await loadSetting(db, 'theme'), 'dark');
    expect(await loadSetting(db, 'font_scale'), '1.2');
  });
}
