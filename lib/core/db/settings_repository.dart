import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'user_database.dart';

const _uuid = Uuid();

/// Generic key-value persistence over the Settings table -- any feature
/// that needs one durable value (a JSON blob, a flag, a scalar) uses
/// this directly rather than growing its own one-off table.
Future<void> saveSetting(UserDatabase db, String key, String value) async {
  final existing = await (db.select(db.settings)..where((s) => s.key.equals(key))..limit(1)).getSingleOrNull();

  if (existing != null) {
    await (db.update(db.settings)..where((s) => s.id.equals(existing.id))).write(
      SettingsCompanion(
        value: Value(value),
        updatedAt: Value(DateTime.now()),
        dirty: const Value(true),
      ),
    );
  } else {
    await db.into(db.settings).insert(SettingsCompanion.insert(id: _uuid.v4(), key: key, value: value));
  }
}

Future<String?> loadSetting(UserDatabase db, String key) async {
  final row = await (db.select(db.settings)..where((s) => s.key.equals(key))..limit(1)).getSingleOrNull();
  return row?.value;
}
