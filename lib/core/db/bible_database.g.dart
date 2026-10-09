// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bible_database.dart';

// ignore_for_file: type=lint
class $TranslationsTable extends Translations
    with TableInfo<$TranslationsTable, Translation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranslationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shortNameMeta = const VerificationMeta(
    'shortName',
  );
  @override
  late final GeneratedColumn<String> shortName = GeneratedColumn<String>(
    'short_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageCodeMeta = const VerificationMeta(
    'languageCode',
  );
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
    'language_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publisherMeta = const VerificationMeta(
    'publisher',
  );
  @override
  late final GeneratedColumn<String> publisher = GeneratedColumn<String>(
    'publisher',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rightsStatusMeta = const VerificationMeta(
    'rightsStatus',
  );
  @override
  late final GeneratedColumn<String> rightsStatus = GeneratedColumn<String>(
    'rights_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rightsNotesMeta = const VerificationMeta(
    'rightsNotes',
  );
  @override
  late final GeneratedColumn<String> rightsNotes = GeneratedColumn<String>(
    'rights_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _licenseTextMeta = const VerificationMeta(
    'licenseText',
  );
  @override
  late final GeneratedColumn<String> licenseText = GeneratedColumn<String>(
    'license_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    shortName,
    languageCode,
    year,
    publisher,
    rightsStatus,
    rightsNotes,
    licenseText,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'translations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Translation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('short_name')) {
      context.handle(
        _shortNameMeta,
        shortName.isAcceptableOrUnknown(data['short_name']!, _shortNameMeta),
      );
    } else if (isInserting) {
      context.missing(_shortNameMeta);
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_languageCodeMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('publisher')) {
      context.handle(
        _publisherMeta,
        publisher.isAcceptableOrUnknown(data['publisher']!, _publisherMeta),
      );
    }
    if (data.containsKey('rights_status')) {
      context.handle(
        _rightsStatusMeta,
        rightsStatus.isAcceptableOrUnknown(
          data['rights_status']!,
          _rightsStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rightsStatusMeta);
    }
    if (data.containsKey('rights_notes')) {
      context.handle(
        _rightsNotesMeta,
        rightsNotes.isAcceptableOrUnknown(
          data['rights_notes']!,
          _rightsNotesMeta,
        ),
      );
    }
    if (data.containsKey('license_text')) {
      context.handle(
        _licenseTextMeta,
        licenseText.isAcceptableOrUnknown(
          data['license_text']!,
          _licenseTextMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Translation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Translation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      shortName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}short_name'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      publisher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publisher'],
      ),
      rightsStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rights_status'],
      )!,
      rightsNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rights_notes'],
      ),
      licenseText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}license_text'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $TranslationsTable createAlias(String alias) {
    return $TranslationsTable(attachedDatabase, alias);
  }
}

class Translation extends DataClass implements Insertable<Translation> {
  final String id;
  final String name;
  final String shortName;
  final String languageCode;
  final int? year;
  final String? publisher;
  final String rightsStatus;
  final String? rightsNotes;
  final String? licenseText;
  final int sortOrder;
  const Translation({
    required this.id,
    required this.name,
    required this.shortName,
    required this.languageCode,
    this.year,
    this.publisher,
    required this.rightsStatus,
    this.rightsNotes,
    this.licenseText,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['short_name'] = Variable<String>(shortName);
    map['language_code'] = Variable<String>(languageCode);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || publisher != null) {
      map['publisher'] = Variable<String>(publisher);
    }
    map['rights_status'] = Variable<String>(rightsStatus);
    if (!nullToAbsent || rightsNotes != null) {
      map['rights_notes'] = Variable<String>(rightsNotes);
    }
    if (!nullToAbsent || licenseText != null) {
      map['license_text'] = Variable<String>(licenseText);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TranslationsCompanion toCompanion(bool nullToAbsent) {
    return TranslationsCompanion(
      id: Value(id),
      name: Value(name),
      shortName: Value(shortName),
      languageCode: Value(languageCode),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      publisher: publisher == null && nullToAbsent
          ? const Value.absent()
          : Value(publisher),
      rightsStatus: Value(rightsStatus),
      rightsNotes: rightsNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(rightsNotes),
      licenseText: licenseText == null && nullToAbsent
          ? const Value.absent()
          : Value(licenseText),
      sortOrder: Value(sortOrder),
    );
  }

  factory Translation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Translation(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      shortName: serializer.fromJson<String>(json['shortName']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      year: serializer.fromJson<int?>(json['year']),
      publisher: serializer.fromJson<String?>(json['publisher']),
      rightsStatus: serializer.fromJson<String>(json['rightsStatus']),
      rightsNotes: serializer.fromJson<String?>(json['rightsNotes']),
      licenseText: serializer.fromJson<String?>(json['licenseText']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'shortName': serializer.toJson<String>(shortName),
      'languageCode': serializer.toJson<String>(languageCode),
      'year': serializer.toJson<int?>(year),
      'publisher': serializer.toJson<String?>(publisher),
      'rightsStatus': serializer.toJson<String>(rightsStatus),
      'rightsNotes': serializer.toJson<String?>(rightsNotes),
      'licenseText': serializer.toJson<String?>(licenseText),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Translation copyWith({
    String? id,
    String? name,
    String? shortName,
    String? languageCode,
    Value<int?> year = const Value.absent(),
    Value<String?> publisher = const Value.absent(),
    String? rightsStatus,
    Value<String?> rightsNotes = const Value.absent(),
    Value<String?> licenseText = const Value.absent(),
    int? sortOrder,
  }) => Translation(
    id: id ?? this.id,
    name: name ?? this.name,
    shortName: shortName ?? this.shortName,
    languageCode: languageCode ?? this.languageCode,
    year: year.present ? year.value : this.year,
    publisher: publisher.present ? publisher.value : this.publisher,
    rightsStatus: rightsStatus ?? this.rightsStatus,
    rightsNotes: rightsNotes.present ? rightsNotes.value : this.rightsNotes,
    licenseText: licenseText.present ? licenseText.value : this.licenseText,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Translation copyWithCompanion(TranslationsCompanion data) {
    return Translation(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      shortName: data.shortName.present ? data.shortName.value : this.shortName,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      year: data.year.present ? data.year.value : this.year,
      publisher: data.publisher.present ? data.publisher.value : this.publisher,
      rightsStatus: data.rightsStatus.present
          ? data.rightsStatus.value
          : this.rightsStatus,
      rightsNotes: data.rightsNotes.present
          ? data.rightsNotes.value
          : this.rightsNotes,
      licenseText: data.licenseText.present
          ? data.licenseText.value
          : this.licenseText,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Translation(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('shortName: $shortName, ')
          ..write('languageCode: $languageCode, ')
          ..write('year: $year, ')
          ..write('publisher: $publisher, ')
          ..write('rightsStatus: $rightsStatus, ')
          ..write('rightsNotes: $rightsNotes, ')
          ..write('licenseText: $licenseText, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    shortName,
    languageCode,
    year,
    publisher,
    rightsStatus,
    rightsNotes,
    licenseText,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Translation &&
          other.id == this.id &&
          other.name == this.name &&
          other.shortName == this.shortName &&
          other.languageCode == this.languageCode &&
          other.year == this.year &&
          other.publisher == this.publisher &&
          other.rightsStatus == this.rightsStatus &&
          other.rightsNotes == this.rightsNotes &&
          other.licenseText == this.licenseText &&
          other.sortOrder == this.sortOrder);
}

class TranslationsCompanion extends UpdateCompanion<Translation> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> shortName;
  final Value<String> languageCode;
  final Value<int?> year;
  final Value<String?> publisher;
  final Value<String> rightsStatus;
  final Value<String?> rightsNotes;
  final Value<String?> licenseText;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const TranslationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.shortName = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.year = const Value.absent(),
    this.publisher = const Value.absent(),
    this.rightsStatus = const Value.absent(),
    this.rightsNotes = const Value.absent(),
    this.licenseText = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TranslationsCompanion.insert({
    required String id,
    required String name,
    required String shortName,
    required String languageCode,
    this.year = const Value.absent(),
    this.publisher = const Value.absent(),
    required String rightsStatus,
    this.rightsNotes = const Value.absent(),
    this.licenseText = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       shortName = Value(shortName),
       languageCode = Value(languageCode),
       rightsStatus = Value(rightsStatus),
       sortOrder = Value(sortOrder);
  static Insertable<Translation> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? shortName,
    Expression<String>? languageCode,
    Expression<int>? year,
    Expression<String>? publisher,
    Expression<String>? rightsStatus,
    Expression<String>? rightsNotes,
    Expression<String>? licenseText,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (shortName != null) 'short_name': shortName,
      if (languageCode != null) 'language_code': languageCode,
      if (year != null) 'year': year,
      if (publisher != null) 'publisher': publisher,
      if (rightsStatus != null) 'rights_status': rightsStatus,
      if (rightsNotes != null) 'rights_notes': rightsNotes,
      if (licenseText != null) 'license_text': licenseText,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TranslationsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? shortName,
    Value<String>? languageCode,
    Value<int?>? year,
    Value<String?>? publisher,
    Value<String>? rightsStatus,
    Value<String?>? rightsNotes,
    Value<String?>? licenseText,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return TranslationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      languageCode: languageCode ?? this.languageCode,
      year: year ?? this.year,
      publisher: publisher ?? this.publisher,
      rightsStatus: rightsStatus ?? this.rightsStatus,
      rightsNotes: rightsNotes ?? this.rightsNotes,
      licenseText: licenseText ?? this.licenseText,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (shortName.present) {
      map['short_name'] = Variable<String>(shortName.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (publisher.present) {
      map['publisher'] = Variable<String>(publisher.value);
    }
    if (rightsStatus.present) {
      map['rights_status'] = Variable<String>(rightsStatus.value);
    }
    if (rightsNotes.present) {
      map['rights_notes'] = Variable<String>(rightsNotes.value);
    }
    if (licenseText.present) {
      map['license_text'] = Variable<String>(licenseText.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranslationsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('shortName: $shortName, ')
          ..write('languageCode: $languageCode, ')
          ..write('year: $year, ')
          ..write('publisher: $publisher, ')
          ..write('rightsStatus: $rightsStatus, ')
          ..write('rightsNotes: $rightsNotes, ')
          ..write('licenseText: $licenseText, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BooksTable extends Books with TableInfo<$BooksTable, Book> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _testamentMeta = const VerificationMeta(
    'testament',
  );
  @override
  late final GeneratedColumn<String> testament = GeneratedColumn<String>(
    'testament',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterCountMeta = const VerificationMeta(
    'chapterCount',
  );
  @override
  late final GeneratedColumn<int> chapterCount = GeneratedColumn<int>(
    'chapter_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _osisCodeMeta = const VerificationMeta(
    'osisCode',
  );
  @override
  late final GeneratedColumn<String> osisCode = GeneratedColumn<String>(
    'osis_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, testament, chapterCount, osisCode];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(
    Insertable<Book> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('testament')) {
      context.handle(
        _testamentMeta,
        testament.isAcceptableOrUnknown(data['testament']!, _testamentMeta),
      );
    } else if (isInserting) {
      context.missing(_testamentMeta);
    }
    if (data.containsKey('chapter_count')) {
      context.handle(
        _chapterCountMeta,
        chapterCount.isAcceptableOrUnknown(
          data['chapter_count']!,
          _chapterCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chapterCountMeta);
    }
    if (data.containsKey('osis_code')) {
      context.handle(
        _osisCodeMeta,
        osisCode.isAcceptableOrUnknown(data['osis_code']!, _osisCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_osisCodeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Book map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Book(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      testament: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}testament'],
      )!,
      chapterCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_count'],
      )!,
      osisCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}osis_code'],
      )!,
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }
}

class Book extends DataClass implements Insertable<Book> {
  final int id;
  final String testament;
  final int chapterCount;
  final String osisCode;
  const Book({
    required this.id,
    required this.testament,
    required this.chapterCount,
    required this.osisCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['testament'] = Variable<String>(testament);
    map['chapter_count'] = Variable<int>(chapterCount);
    map['osis_code'] = Variable<String>(osisCode);
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      testament: Value(testament),
      chapterCount: Value(chapterCount),
      osisCode: Value(osisCode),
    );
  }

  factory Book.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Book(
      id: serializer.fromJson<int>(json['id']),
      testament: serializer.fromJson<String>(json['testament']),
      chapterCount: serializer.fromJson<int>(json['chapterCount']),
      osisCode: serializer.fromJson<String>(json['osisCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'testament': serializer.toJson<String>(testament),
      'chapterCount': serializer.toJson<int>(chapterCount),
      'osisCode': serializer.toJson<String>(osisCode),
    };
  }

  Book copyWith({
    int? id,
    String? testament,
    int? chapterCount,
    String? osisCode,
  }) => Book(
    id: id ?? this.id,
    testament: testament ?? this.testament,
    chapterCount: chapterCount ?? this.chapterCount,
    osisCode: osisCode ?? this.osisCode,
  );
  Book copyWithCompanion(BooksCompanion data) {
    return Book(
      id: data.id.present ? data.id.value : this.id,
      testament: data.testament.present ? data.testament.value : this.testament,
      chapterCount: data.chapterCount.present
          ? data.chapterCount.value
          : this.chapterCount,
      osisCode: data.osisCode.present ? data.osisCode.value : this.osisCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Book(')
          ..write('id: $id, ')
          ..write('testament: $testament, ')
          ..write('chapterCount: $chapterCount, ')
          ..write('osisCode: $osisCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, testament, chapterCount, osisCode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Book &&
          other.id == this.id &&
          other.testament == this.testament &&
          other.chapterCount == this.chapterCount &&
          other.osisCode == this.osisCode);
}

class BooksCompanion extends UpdateCompanion<Book> {
  final Value<int> id;
  final Value<String> testament;
  final Value<int> chapterCount;
  final Value<String> osisCode;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.testament = const Value.absent(),
    this.chapterCount = const Value.absent(),
    this.osisCode = const Value.absent(),
  });
  BooksCompanion.insert({
    this.id = const Value.absent(),
    required String testament,
    required int chapterCount,
    required String osisCode,
  }) : testament = Value(testament),
       chapterCount = Value(chapterCount),
       osisCode = Value(osisCode);
  static Insertable<Book> custom({
    Expression<int>? id,
    Expression<String>? testament,
    Expression<int>? chapterCount,
    Expression<String>? osisCode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (testament != null) 'testament': testament,
      if (chapterCount != null) 'chapter_count': chapterCount,
      if (osisCode != null) 'osis_code': osisCode,
    });
  }

  BooksCompanion copyWith({
    Value<int>? id,
    Value<String>? testament,
    Value<int>? chapterCount,
    Value<String>? osisCode,
  }) {
    return BooksCompanion(
      id: id ?? this.id,
      testament: testament ?? this.testament,
      chapterCount: chapterCount ?? this.chapterCount,
      osisCode: osisCode ?? this.osisCode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (testament.present) {
      map['testament'] = Variable<String>(testament.value);
    }
    if (chapterCount.present) {
      map['chapter_count'] = Variable<int>(chapterCount.value);
    }
    if (osisCode.present) {
      map['osis_code'] = Variable<String>(osisCode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('testament: $testament, ')
          ..write('chapterCount: $chapterCount, ')
          ..write('osisCode: $osisCode')
          ..write(')'))
        .toString();
  }
}

class $BookNamesTable extends BookNames
    with TableInfo<$BookNamesTable, BookName> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookNamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id)',
    ),
  );
  static const VerificationMeta _translationIdMeta = const VerificationMeta(
    'translationId',
  );
  @override
  late final GeneratedColumn<String> translationId = GeneratedColumn<String>(
    'translation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES translations (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shortNameMeta = const VerificationMeta(
    'shortName',
  );
  @override
  late final GeneratedColumn<String> shortName = GeneratedColumn<String>(
    'short_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bookId,
    translationId,
    name,
    shortName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_names';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookName> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('translation_id')) {
      context.handle(
        _translationIdMeta,
        translationId.isAcceptableOrUnknown(
          data['translation_id']!,
          _translationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translationIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('short_name')) {
      context.handle(
        _shortNameMeta,
        shortName.isAcceptableOrUnknown(data['short_name']!, _shortNameMeta),
      );
    } else if (isInserting) {
      context.missing(_shortNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookId, translationId};
  @override
  BookName map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookName(
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      translationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      shortName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}short_name'],
      )!,
    );
  }

  @override
  $BookNamesTable createAlias(String alias) {
    return $BookNamesTable(attachedDatabase, alias);
  }
}

class BookName extends DataClass implements Insertable<BookName> {
  final int bookId;
  final String translationId;
  final String name;
  final String shortName;
  const BookName({
    required this.bookId,
    required this.translationId,
    required this.name,
    required this.shortName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<int>(bookId);
    map['translation_id'] = Variable<String>(translationId);
    map['name'] = Variable<String>(name);
    map['short_name'] = Variable<String>(shortName);
    return map;
  }

  BookNamesCompanion toCompanion(bool nullToAbsent) {
    return BookNamesCompanion(
      bookId: Value(bookId),
      translationId: Value(translationId),
      name: Value(name),
      shortName: Value(shortName),
    );
  }

  factory BookName.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookName(
      bookId: serializer.fromJson<int>(json['bookId']),
      translationId: serializer.fromJson<String>(json['translationId']),
      name: serializer.fromJson<String>(json['name']),
      shortName: serializer.fromJson<String>(json['shortName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookId': serializer.toJson<int>(bookId),
      'translationId': serializer.toJson<String>(translationId),
      'name': serializer.toJson<String>(name),
      'shortName': serializer.toJson<String>(shortName),
    };
  }

  BookName copyWith({
    int? bookId,
    String? translationId,
    String? name,
    String? shortName,
  }) => BookName(
    bookId: bookId ?? this.bookId,
    translationId: translationId ?? this.translationId,
    name: name ?? this.name,
    shortName: shortName ?? this.shortName,
  );
  BookName copyWithCompanion(BookNamesCompanion data) {
    return BookName(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      translationId: data.translationId.present
          ? data.translationId.value
          : this.translationId,
      name: data.name.present ? data.name.value : this.name,
      shortName: data.shortName.present ? data.shortName.value : this.shortName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookName(')
          ..write('bookId: $bookId, ')
          ..write('translationId: $translationId, ')
          ..write('name: $name, ')
          ..write('shortName: $shortName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(bookId, translationId, name, shortName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookName &&
          other.bookId == this.bookId &&
          other.translationId == this.translationId &&
          other.name == this.name &&
          other.shortName == this.shortName);
}

class BookNamesCompanion extends UpdateCompanion<BookName> {
  final Value<int> bookId;
  final Value<String> translationId;
  final Value<String> name;
  final Value<String> shortName;
  final Value<int> rowid;
  const BookNamesCompanion({
    this.bookId = const Value.absent(),
    this.translationId = const Value.absent(),
    this.name = const Value.absent(),
    this.shortName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookNamesCompanion.insert({
    required int bookId,
    required String translationId,
    required String name,
    required String shortName,
    this.rowid = const Value.absent(),
  }) : bookId = Value(bookId),
       translationId = Value(translationId),
       name = Value(name),
       shortName = Value(shortName);
  static Insertable<BookName> custom({
    Expression<int>? bookId,
    Expression<String>? translationId,
    Expression<String>? name,
    Expression<String>? shortName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (translationId != null) 'translation_id': translationId,
      if (name != null) 'name': name,
      if (shortName != null) 'short_name': shortName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookNamesCompanion copyWith({
    Value<int>? bookId,
    Value<String>? translationId,
    Value<String>? name,
    Value<String>? shortName,
    Value<int>? rowid,
  }) {
    return BookNamesCompanion(
      bookId: bookId ?? this.bookId,
      translationId: translationId ?? this.translationId,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (translationId.present) {
      map['translation_id'] = Variable<String>(translationId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (shortName.present) {
      map['short_name'] = Variable<String>(shortName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookNamesCompanion(')
          ..write('bookId: $bookId, ')
          ..write('translationId: $translationId, ')
          ..write('name: $name, ')
          ..write('shortName: $shortName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VersesTable extends Verses with TableInfo<$VersesTable, Verse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VersesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _translationIdMeta = const VerificationMeta(
    'translationId',
  );
  @override
  late final GeneratedColumn<String> translationId = GeneratedColumn<String>(
    'translation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES translations (id)',
    ),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id)',
    ),
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verseMeta = const VerificationMeta('verse');
  @override
  late final GeneratedColumn<int> verse = GeneratedColumn<int>(
    'verse',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verseTextMeta = const VerificationMeta(
    'verseText',
  );
  @override
  late final GeneratedColumn<String> verseText = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textFoldedMeta = const VerificationMeta(
    'textFolded',
  );
  @override
  late final GeneratedColumn<String> textFolded = GeneratedColumn<String>(
    'text_folded',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _headingMeta = const VerificationMeta(
    'heading',
  );
  @override
  late final GeneratedColumn<String> heading = GeneratedColumn<String>(
    'heading',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _crossRefMeta = const VerificationMeta(
    'crossRef',
  );
  @override
  late final GeneratedColumn<String> crossRef = GeneratedColumn<String>(
    'cross_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    translationId,
    bookId,
    chapter,
    verse,
    verseText,
    textFolded,
    heading,
    crossRef,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'verses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Verse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('translation_id')) {
      context.handle(
        _translationIdMeta,
        translationId.isAcceptableOrUnknown(
          data['translation_id']!,
          _translationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translationIdMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('verse')) {
      context.handle(
        _verseMeta,
        verse.isAcceptableOrUnknown(data['verse']!, _verseMeta),
      );
    } else if (isInserting) {
      context.missing(_verseMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _verseTextMeta,
        verseText.isAcceptableOrUnknown(data['text']!, _verseTextMeta),
      );
    } else if (isInserting) {
      context.missing(_verseTextMeta);
    }
    if (data.containsKey('text_folded')) {
      context.handle(
        _textFoldedMeta,
        textFolded.isAcceptableOrUnknown(data['text_folded']!, _textFoldedMeta),
      );
    } else if (isInserting) {
      context.missing(_textFoldedMeta);
    }
    if (data.containsKey('heading')) {
      context.handle(
        _headingMeta,
        heading.isAcceptableOrUnknown(data['heading']!, _headingMeta),
      );
    }
    if (data.containsKey('cross_ref')) {
      context.handle(
        _crossRefMeta,
        crossRef.isAcceptableOrUnknown(data['cross_ref']!, _crossRefMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    translationId,
    bookId,
    chapter,
    verse,
  };
  @override
  Verse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Verse(
      translationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation_id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      verse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}verse'],
      )!,
      verseText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      textFolded: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_folded'],
      )!,
      heading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}heading'],
      ),
      crossRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cross_ref'],
      ),
    );
  }

  @override
  $VersesTable createAlias(String alias) {
    return $VersesTable(attachedDatabase, alias);
  }
}

class Verse extends DataClass implements Insertable<Verse> {
  final String translationId;
  final int bookId;
  final int chapter;
  final int verse;
  final String verseText;
  final String textFolded;
  final String? heading;
  final String? crossRef;
  const Verse({
    required this.translationId,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.verseText,
    required this.textFolded,
    this.heading,
    this.crossRef,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['translation_id'] = Variable<String>(translationId);
    map['book_id'] = Variable<int>(bookId);
    map['chapter'] = Variable<int>(chapter);
    map['verse'] = Variable<int>(verse);
    map['text'] = Variable<String>(verseText);
    map['text_folded'] = Variable<String>(textFolded);
    if (!nullToAbsent || heading != null) {
      map['heading'] = Variable<String>(heading);
    }
    if (!nullToAbsent || crossRef != null) {
      map['cross_ref'] = Variable<String>(crossRef);
    }
    return map;
  }

  VersesCompanion toCompanion(bool nullToAbsent) {
    return VersesCompanion(
      translationId: Value(translationId),
      bookId: Value(bookId),
      chapter: Value(chapter),
      verse: Value(verse),
      verseText: Value(verseText),
      textFolded: Value(textFolded),
      heading: heading == null && nullToAbsent
          ? const Value.absent()
          : Value(heading),
      crossRef: crossRef == null && nullToAbsent
          ? const Value.absent()
          : Value(crossRef),
    );
  }

  factory Verse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Verse(
      translationId: serializer.fromJson<String>(json['translationId']),
      bookId: serializer.fromJson<int>(json['bookId']),
      chapter: serializer.fromJson<int>(json['chapter']),
      verse: serializer.fromJson<int>(json['verse']),
      verseText: serializer.fromJson<String>(json['verseText']),
      textFolded: serializer.fromJson<String>(json['textFolded']),
      heading: serializer.fromJson<String?>(json['heading']),
      crossRef: serializer.fromJson<String?>(json['crossRef']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'translationId': serializer.toJson<String>(translationId),
      'bookId': serializer.toJson<int>(bookId),
      'chapter': serializer.toJson<int>(chapter),
      'verse': serializer.toJson<int>(verse),
      'verseText': serializer.toJson<String>(verseText),
      'textFolded': serializer.toJson<String>(textFolded),
      'heading': serializer.toJson<String?>(heading),
      'crossRef': serializer.toJson<String?>(crossRef),
    };
  }

  Verse copyWith({
    String? translationId,
    int? bookId,
    int? chapter,
    int? verse,
    String? verseText,
    String? textFolded,
    Value<String?> heading = const Value.absent(),
    Value<String?> crossRef = const Value.absent(),
  }) => Verse(
    translationId: translationId ?? this.translationId,
    bookId: bookId ?? this.bookId,
    chapter: chapter ?? this.chapter,
    verse: verse ?? this.verse,
    verseText: verseText ?? this.verseText,
    textFolded: textFolded ?? this.textFolded,
    heading: heading.present ? heading.value : this.heading,
    crossRef: crossRef.present ? crossRef.value : this.crossRef,
  );
  Verse copyWithCompanion(VersesCompanion data) {
    return Verse(
      translationId: data.translationId.present
          ? data.translationId.value
          : this.translationId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      verse: data.verse.present ? data.verse.value : this.verse,
      verseText: data.verseText.present ? data.verseText.value : this.verseText,
      textFolded: data.textFolded.present
          ? data.textFolded.value
          : this.textFolded,
      heading: data.heading.present ? data.heading.value : this.heading,
      crossRef: data.crossRef.present ? data.crossRef.value : this.crossRef,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Verse(')
          ..write('translationId: $translationId, ')
          ..write('bookId: $bookId, ')
          ..write('chapter: $chapter, ')
          ..write('verse: $verse, ')
          ..write('verseText: $verseText, ')
          ..write('textFolded: $textFolded, ')
          ..write('heading: $heading, ')
          ..write('crossRef: $crossRef')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    translationId,
    bookId,
    chapter,
    verse,
    verseText,
    textFolded,
    heading,
    crossRef,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Verse &&
          other.translationId == this.translationId &&
          other.bookId == this.bookId &&
          other.chapter == this.chapter &&
          other.verse == this.verse &&
          other.verseText == this.verseText &&
          other.textFolded == this.textFolded &&
          other.heading == this.heading &&
          other.crossRef == this.crossRef);
}

class VersesCompanion extends UpdateCompanion<Verse> {
  final Value<String> translationId;
  final Value<int> bookId;
  final Value<int> chapter;
  final Value<int> verse;
  final Value<String> verseText;
  final Value<String> textFolded;
  final Value<String?> heading;
  final Value<String?> crossRef;
  final Value<int> rowid;
  const VersesCompanion({
    this.translationId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.chapter = const Value.absent(),
    this.verse = const Value.absent(),
    this.verseText = const Value.absent(),
    this.textFolded = const Value.absent(),
    this.heading = const Value.absent(),
    this.crossRef = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VersesCompanion.insert({
    required String translationId,
    required int bookId,
    required int chapter,
    required int verse,
    required String verseText,
    required String textFolded,
    this.heading = const Value.absent(),
    this.crossRef = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : translationId = Value(translationId),
       bookId = Value(bookId),
       chapter = Value(chapter),
       verse = Value(verse),
       verseText = Value(verseText),
       textFolded = Value(textFolded);
  static Insertable<Verse> custom({
    Expression<String>? translationId,
    Expression<int>? bookId,
    Expression<int>? chapter,
    Expression<int>? verse,
    Expression<String>? verseText,
    Expression<String>? textFolded,
    Expression<String>? heading,
    Expression<String>? crossRef,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (translationId != null) 'translation_id': translationId,
      if (bookId != null) 'book_id': bookId,
      if (chapter != null) 'chapter': chapter,
      if (verse != null) 'verse': verse,
      if (verseText != null) 'text': verseText,
      if (textFolded != null) 'text_folded': textFolded,
      if (heading != null) 'heading': heading,
      if (crossRef != null) 'cross_ref': crossRef,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VersesCompanion copyWith({
    Value<String>? translationId,
    Value<int>? bookId,
    Value<int>? chapter,
    Value<int>? verse,
    Value<String>? verseText,
    Value<String>? textFolded,
    Value<String?>? heading,
    Value<String?>? crossRef,
    Value<int>? rowid,
  }) {
    return VersesCompanion(
      translationId: translationId ?? this.translationId,
      bookId: bookId ?? this.bookId,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      verseText: verseText ?? this.verseText,
      textFolded: textFolded ?? this.textFolded,
      heading: heading ?? this.heading,
      crossRef: crossRef ?? this.crossRef,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (translationId.present) {
      map['translation_id'] = Variable<String>(translationId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (verse.present) {
      map['verse'] = Variable<int>(verse.value);
    }
    if (verseText.present) {
      map['text'] = Variable<String>(verseText.value);
    }
    if (textFolded.present) {
      map['text_folded'] = Variable<String>(textFolded.value);
    }
    if (heading.present) {
      map['heading'] = Variable<String>(heading.value);
    }
    if (crossRef.present) {
      map['cross_ref'] = Variable<String>(crossRef.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VersesCompanion(')
          ..write('translationId: $translationId, ')
          ..write('bookId: $bookId, ')
          ..write('chapter: $chapter, ')
          ..write('verse: $verse, ')
          ..write('verseText: $verseText, ')
          ..write('textFolded: $textFolded, ')
          ..write('heading: $heading, ')
          ..write('crossRef: $crossRef, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ParallelRowsTable extends ParallelRows
    with TableInfo<$ParallelRowsTable, ParallelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ParallelRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pairIdMeta = const VerificationMeta('pairId');
  @override
  late final GeneratedColumn<String> pairId = GeneratedColumn<String>(
    'pair_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id)',
    ),
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIndexMeta = const VerificationMeta(
    'rowIndex',
  );
  @override
  late final GeneratedColumn<int> rowIndex = GeneratedColumn<int>(
    'row_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aStartMeta = const VerificationMeta('aStart');
  @override
  late final GeneratedColumn<int> aStart = GeneratedColumn<int>(
    'a_start',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aEndMeta = const VerificationMeta('aEnd');
  @override
  late final GeneratedColumn<int> aEnd = GeneratedColumn<int>(
    'a_end',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bStartMeta = const VerificationMeta('bStart');
  @override
  late final GeneratedColumn<int> bStart = GeneratedColumn<int>(
    'b_start',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bEndMeta = const VerificationMeta('bEnd');
  @override
  late final GeneratedColumn<int> bEnd = GeneratedColumn<int>(
    'b_end',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    pairId,
    bookId,
    chapter,
    rowIndex,
    label,
    aStart,
    aEnd,
    bStart,
    bEnd,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'parallel_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ParallelRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pair_id')) {
      context.handle(
        _pairIdMeta,
        pairId.isAcceptableOrUnknown(data['pair_id']!, _pairIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pairIdMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('row_index')) {
      context.handle(
        _rowIndexMeta,
        rowIndex.isAcceptableOrUnknown(data['row_index']!, _rowIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIndexMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('a_start')) {
      context.handle(
        _aStartMeta,
        aStart.isAcceptableOrUnknown(data['a_start']!, _aStartMeta),
      );
    }
    if (data.containsKey('a_end')) {
      context.handle(
        _aEndMeta,
        aEnd.isAcceptableOrUnknown(data['a_end']!, _aEndMeta),
      );
    }
    if (data.containsKey('b_start')) {
      context.handle(
        _bStartMeta,
        bStart.isAcceptableOrUnknown(data['b_start']!, _bStartMeta),
      );
    }
    if (data.containsKey('b_end')) {
      context.handle(
        _bEndMeta,
        bEnd.isAcceptableOrUnknown(data['b_end']!, _bEndMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pairId, bookId, chapter, rowIndex};
  @override
  ParallelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ParallelRow(
      pairId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pair_id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      rowIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_index'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      aStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}a_start'],
      ),
      aEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}a_end'],
      ),
      bStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}b_start'],
      ),
      bEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}b_end'],
      ),
    );
  }

  @override
  $ParallelRowsTable createAlias(String alias) {
    return $ParallelRowsTable(attachedDatabase, alias);
  }
}

class ParallelRow extends DataClass implements Insertable<ParallelRow> {
  final String pairId;
  final int bookId;
  final int chapter;
  final int rowIndex;
  final String label;
  final int? aStart;
  final int? aEnd;
  final int? bStart;
  final int? bEnd;
  const ParallelRow({
    required this.pairId,
    required this.bookId,
    required this.chapter,
    required this.rowIndex,
    required this.label,
    this.aStart,
    this.aEnd,
    this.bStart,
    this.bEnd,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pair_id'] = Variable<String>(pairId);
    map['book_id'] = Variable<int>(bookId);
    map['chapter'] = Variable<int>(chapter);
    map['row_index'] = Variable<int>(rowIndex);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || aStart != null) {
      map['a_start'] = Variable<int>(aStart);
    }
    if (!nullToAbsent || aEnd != null) {
      map['a_end'] = Variable<int>(aEnd);
    }
    if (!nullToAbsent || bStart != null) {
      map['b_start'] = Variable<int>(bStart);
    }
    if (!nullToAbsent || bEnd != null) {
      map['b_end'] = Variable<int>(bEnd);
    }
    return map;
  }

  ParallelRowsCompanion toCompanion(bool nullToAbsent) {
    return ParallelRowsCompanion(
      pairId: Value(pairId),
      bookId: Value(bookId),
      chapter: Value(chapter),
      rowIndex: Value(rowIndex),
      label: Value(label),
      aStart: aStart == null && nullToAbsent
          ? const Value.absent()
          : Value(aStart),
      aEnd: aEnd == null && nullToAbsent ? const Value.absent() : Value(aEnd),
      bStart: bStart == null && nullToAbsent
          ? const Value.absent()
          : Value(bStart),
      bEnd: bEnd == null && nullToAbsent ? const Value.absent() : Value(bEnd),
    );
  }

  factory ParallelRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ParallelRow(
      pairId: serializer.fromJson<String>(json['pairId']),
      bookId: serializer.fromJson<int>(json['bookId']),
      chapter: serializer.fromJson<int>(json['chapter']),
      rowIndex: serializer.fromJson<int>(json['rowIndex']),
      label: serializer.fromJson<String>(json['label']),
      aStart: serializer.fromJson<int?>(json['aStart']),
      aEnd: serializer.fromJson<int?>(json['aEnd']),
      bStart: serializer.fromJson<int?>(json['bStart']),
      bEnd: serializer.fromJson<int?>(json['bEnd']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pairId': serializer.toJson<String>(pairId),
      'bookId': serializer.toJson<int>(bookId),
      'chapter': serializer.toJson<int>(chapter),
      'rowIndex': serializer.toJson<int>(rowIndex),
      'label': serializer.toJson<String>(label),
      'aStart': serializer.toJson<int?>(aStart),
      'aEnd': serializer.toJson<int?>(aEnd),
      'bStart': serializer.toJson<int?>(bStart),
      'bEnd': serializer.toJson<int?>(bEnd),
    };
  }

  ParallelRow copyWith({
    String? pairId,
    int? bookId,
    int? chapter,
    int? rowIndex,
    String? label,
    Value<int?> aStart = const Value.absent(),
    Value<int?> aEnd = const Value.absent(),
    Value<int?> bStart = const Value.absent(),
    Value<int?> bEnd = const Value.absent(),
  }) => ParallelRow(
    pairId: pairId ?? this.pairId,
    bookId: bookId ?? this.bookId,
    chapter: chapter ?? this.chapter,
    rowIndex: rowIndex ?? this.rowIndex,
    label: label ?? this.label,
    aStart: aStart.present ? aStart.value : this.aStart,
    aEnd: aEnd.present ? aEnd.value : this.aEnd,
    bStart: bStart.present ? bStart.value : this.bStart,
    bEnd: bEnd.present ? bEnd.value : this.bEnd,
  );
  ParallelRow copyWithCompanion(ParallelRowsCompanion data) {
    return ParallelRow(
      pairId: data.pairId.present ? data.pairId.value : this.pairId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      rowIndex: data.rowIndex.present ? data.rowIndex.value : this.rowIndex,
      label: data.label.present ? data.label.value : this.label,
      aStart: data.aStart.present ? data.aStart.value : this.aStart,
      aEnd: data.aEnd.present ? data.aEnd.value : this.aEnd,
      bStart: data.bStart.present ? data.bStart.value : this.bStart,
      bEnd: data.bEnd.present ? data.bEnd.value : this.bEnd,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ParallelRow(')
          ..write('pairId: $pairId, ')
          ..write('bookId: $bookId, ')
          ..write('chapter: $chapter, ')
          ..write('rowIndex: $rowIndex, ')
          ..write('label: $label, ')
          ..write('aStart: $aStart, ')
          ..write('aEnd: $aEnd, ')
          ..write('bStart: $bStart, ')
          ..write('bEnd: $bEnd')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    pairId,
    bookId,
    chapter,
    rowIndex,
    label,
    aStart,
    aEnd,
    bStart,
    bEnd,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParallelRow &&
          other.pairId == this.pairId &&
          other.bookId == this.bookId &&
          other.chapter == this.chapter &&
          other.rowIndex == this.rowIndex &&
          other.label == this.label &&
          other.aStart == this.aStart &&
          other.aEnd == this.aEnd &&
          other.bStart == this.bStart &&
          other.bEnd == this.bEnd);
}

class ParallelRowsCompanion extends UpdateCompanion<ParallelRow> {
  final Value<String> pairId;
  final Value<int> bookId;
  final Value<int> chapter;
  final Value<int> rowIndex;
  final Value<String> label;
  final Value<int?> aStart;
  final Value<int?> aEnd;
  final Value<int?> bStart;
  final Value<int?> bEnd;
  final Value<int> rowid;
  const ParallelRowsCompanion({
    this.pairId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.chapter = const Value.absent(),
    this.rowIndex = const Value.absent(),
    this.label = const Value.absent(),
    this.aStart = const Value.absent(),
    this.aEnd = const Value.absent(),
    this.bStart = const Value.absent(),
    this.bEnd = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParallelRowsCompanion.insert({
    required String pairId,
    required int bookId,
    required int chapter,
    required int rowIndex,
    required String label,
    this.aStart = const Value.absent(),
    this.aEnd = const Value.absent(),
    this.bStart = const Value.absent(),
    this.bEnd = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : pairId = Value(pairId),
       bookId = Value(bookId),
       chapter = Value(chapter),
       rowIndex = Value(rowIndex),
       label = Value(label);
  static Insertable<ParallelRow> custom({
    Expression<String>? pairId,
    Expression<int>? bookId,
    Expression<int>? chapter,
    Expression<int>? rowIndex,
    Expression<String>? label,
    Expression<int>? aStart,
    Expression<int>? aEnd,
    Expression<int>? bStart,
    Expression<int>? bEnd,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pairId != null) 'pair_id': pairId,
      if (bookId != null) 'book_id': bookId,
      if (chapter != null) 'chapter': chapter,
      if (rowIndex != null) 'row_index': rowIndex,
      if (label != null) 'label': label,
      if (aStart != null) 'a_start': aStart,
      if (aEnd != null) 'a_end': aEnd,
      if (bStart != null) 'b_start': bStart,
      if (bEnd != null) 'b_end': bEnd,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParallelRowsCompanion copyWith({
    Value<String>? pairId,
    Value<int>? bookId,
    Value<int>? chapter,
    Value<int>? rowIndex,
    Value<String>? label,
    Value<int?>? aStart,
    Value<int?>? aEnd,
    Value<int?>? bStart,
    Value<int?>? bEnd,
    Value<int>? rowid,
  }) {
    return ParallelRowsCompanion(
      pairId: pairId ?? this.pairId,
      bookId: bookId ?? this.bookId,
      chapter: chapter ?? this.chapter,
      rowIndex: rowIndex ?? this.rowIndex,
      label: label ?? this.label,
      aStart: aStart ?? this.aStart,
      aEnd: aEnd ?? this.aEnd,
      bStart: bStart ?? this.bStart,
      bEnd: bEnd ?? this.bEnd,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pairId.present) {
      map['pair_id'] = Variable<String>(pairId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (rowIndex.present) {
      map['row_index'] = Variable<int>(rowIndex.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (aStart.present) {
      map['a_start'] = Variable<int>(aStart.value);
    }
    if (aEnd.present) {
      map['a_end'] = Variable<int>(aEnd.value);
    }
    if (bStart.present) {
      map['b_start'] = Variable<int>(bStart.value);
    }
    if (bEnd.present) {
      map['b_end'] = Variable<int>(bEnd.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParallelRowsCompanion(')
          ..write('pairId: $pairId, ')
          ..write('bookId: $bookId, ')
          ..write('chapter: $chapter, ')
          ..write('rowIndex: $rowIndex, ')
          ..write('label: $label, ')
          ..write('aStart: $aStart, ')
          ..write('aEnd: $aEnd, ')
          ..write('bStart: $bStart, ')
          ..write('bEnd: $bEnd, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$BibleDatabase extends GeneratedDatabase {
  _$BibleDatabase(QueryExecutor e) : super(e);
  $BibleDatabaseManager get managers => $BibleDatabaseManager(this);
  late final $TranslationsTable translations = $TranslationsTable(this);
  late final $BooksTable books = $BooksTable(this);
  late final $BookNamesTable bookNames = $BookNamesTable(this);
  late final $VersesTable verses = $VersesTable(this);
  late final $ParallelRowsTable parallelRows = $ParallelRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    translations,
    books,
    bookNames,
    verses,
    parallelRows,
  ];
}

typedef $$TranslationsTableCreateCompanionBuilder =
    TranslationsCompanion Function({
      required String id,
      required String name,
      required String shortName,
      required String languageCode,
      Value<int?> year,
      Value<String?> publisher,
      required String rightsStatus,
      Value<String?> rightsNotes,
      Value<String?> licenseText,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$TranslationsTableUpdateCompanionBuilder =
    TranslationsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> shortName,
      Value<String> languageCode,
      Value<int?> year,
      Value<String?> publisher,
      Value<String> rightsStatus,
      Value<String?> rightsNotes,
      Value<String?> licenseText,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$TranslationsTableReferences
    extends BaseReferences<_$BibleDatabase, $TranslationsTable, Translation> {
  $$TranslationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BookNamesTable, List<BookName>>
  _bookNamesRefsTable(_$BibleDatabase db) => MultiTypedResultKey.fromTable(
    db.bookNames,
    aliasName: 'translations__id__book_names__translation_id',
  );

  $$BookNamesTableProcessedTableManager get bookNamesRefs {
    final manager = $$BookNamesTableTableManager(
      $_db,
      $_db.bookNames,
    ).filter((f) => f.translationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookNamesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VersesTable, List<Verse>> _versesRefsTable(
    _$BibleDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.verses,
    aliasName: 'translations__id__verses__translation_id',
  );

  $$VersesTableProcessedTableManager get versesRefs {
    final manager = $$VersesTableTableManager(
      $_db,
      $_db.verses,
    ).filter((f) => f.translationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_versesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TranslationsTableFilterComposer
    extends Composer<_$BibleDatabase, $TranslationsTable> {
  $$TranslationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shortName => $composableBuilder(
    column: $table.shortName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rightsStatus => $composableBuilder(
    column: $table.rightsStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rightsNotes => $composableBuilder(
    column: $table.rightsNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get licenseText => $composableBuilder(
    column: $table.licenseText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> bookNamesRefs(
    Expression<bool> Function($$BookNamesTableFilterComposer f) f,
  ) {
    final $$BookNamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookNames,
      getReferencedColumn: (t) => t.translationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookNamesTableFilterComposer(
            $db: $db,
            $table: $db.bookNames,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> versesRefs(
    Expression<bool> Function($$VersesTableFilterComposer f) f,
  ) {
    final $$VersesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.verses,
      getReferencedColumn: (t) => t.translationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VersesTableFilterComposer(
            $db: $db,
            $table: $db.verses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TranslationsTableOrderingComposer
    extends Composer<_$BibleDatabase, $TranslationsTable> {
  $$TranslationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shortName => $composableBuilder(
    column: $table.shortName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rightsStatus => $composableBuilder(
    column: $table.rightsStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rightsNotes => $composableBuilder(
    column: $table.rightsNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get licenseText => $composableBuilder(
    column: $table.licenseText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TranslationsTableAnnotationComposer
    extends Composer<_$BibleDatabase, $TranslationsTable> {
  $$TranslationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get shortName =>
      $composableBuilder(column: $table.shortName, builder: (column) => column);

  GeneratedColumn<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get publisher =>
      $composableBuilder(column: $table.publisher, builder: (column) => column);

  GeneratedColumn<String> get rightsStatus => $composableBuilder(
    column: $table.rightsStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rightsNotes => $composableBuilder(
    column: $table.rightsNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get licenseText => $composableBuilder(
    column: $table.licenseText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> bookNamesRefs<T extends Object>(
    Expression<T> Function($$BookNamesTableAnnotationComposer a) f,
  ) {
    final $$BookNamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookNames,
      getReferencedColumn: (t) => t.translationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookNamesTableAnnotationComposer(
            $db: $db,
            $table: $db.bookNames,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> versesRefs<T extends Object>(
    Expression<T> Function($$VersesTableAnnotationComposer a) f,
  ) {
    final $$VersesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.verses,
      getReferencedColumn: (t) => t.translationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VersesTableAnnotationComposer(
            $db: $db,
            $table: $db.verses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TranslationsTableTableManager
    extends
        RootTableManager<
          _$BibleDatabase,
          $TranslationsTable,
          Translation,
          $$TranslationsTableFilterComposer,
          $$TranslationsTableOrderingComposer,
          $$TranslationsTableAnnotationComposer,
          $$TranslationsTableCreateCompanionBuilder,
          $$TranslationsTableUpdateCompanionBuilder,
          (Translation, $$TranslationsTableReferences),
          Translation,
          PrefetchHooks Function({bool bookNamesRefs, bool versesRefs})
        > {
  $$TranslationsTableTableManager(_$BibleDatabase db, $TranslationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TranslationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TranslationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TranslationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> shortName = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> publisher = const Value.absent(),
                Value<String> rightsStatus = const Value.absent(),
                Value<String?> rightsNotes = const Value.absent(),
                Value<String?> licenseText = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TranslationsCompanion(
                id: id,
                name: name,
                shortName: shortName,
                languageCode: languageCode,
                year: year,
                publisher: publisher,
                rightsStatus: rightsStatus,
                rightsNotes: rightsNotes,
                licenseText: licenseText,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String shortName,
                required String languageCode,
                Value<int?> year = const Value.absent(),
                Value<String?> publisher = const Value.absent(),
                required String rightsStatus,
                Value<String?> rightsNotes = const Value.absent(),
                Value<String?> licenseText = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => TranslationsCompanion.insert(
                id: id,
                name: name,
                shortName: shortName,
                languageCode: languageCode,
                year: year,
                publisher: publisher,
                rightsStatus: rightsStatus,
                rightsNotes: rightsNotes,
                licenseText: licenseText,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TranslationsTable, Translation>(table),
                  $$TranslationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookNamesRefs = false, versesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (bookNamesRefs) db.bookNames,
                if (versesRefs) db.verses,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (bookNamesRefs)
                    await $_getPrefetchedData<
                      Translation,
                      $TranslationsTable,
                      BookName
                    >(
                      currentTable: table,
                      referencedTable: $$TranslationsTableReferences
                          ._bookNamesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TranslationsTableReferences(
                            db,
                            table,
                            p0,
                          ).bookNamesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.translationId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (versesRefs)
                    await $_getPrefetchedData<
                      Translation,
                      $TranslationsTable,
                      Verse
                    >(
                      currentTable: table,
                      referencedTable: $$TranslationsTableReferences
                          ._versesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TranslationsTableReferences(
                            db,
                            table,
                            p0,
                          ).versesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.translationId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TranslationsTableProcessedTableManager =
    ProcessedTableManager<
      _$BibleDatabase,
      $TranslationsTable,
      Translation,
      $$TranslationsTableFilterComposer,
      $$TranslationsTableOrderingComposer,
      $$TranslationsTableAnnotationComposer,
      $$TranslationsTableCreateCompanionBuilder,
      $$TranslationsTableUpdateCompanionBuilder,
      (Translation, $$TranslationsTableReferences),
      Translation,
      PrefetchHooks Function({bool bookNamesRefs, bool versesRefs})
    >;
typedef $$BooksTableCreateCompanionBuilder = BooksCompanion Function({
  Value<int> id,
  required String testament,
  required int chapterCount,
  required String osisCode,
});
typedef $$BooksTableUpdateCompanionBuilder = BooksCompanion Function({
  Value<int> id,
  Value<String> testament,
  Value<int> chapterCount,
  Value<String> osisCode,
});

final class $$BooksTableReferences
    extends BaseReferences<_$BibleDatabase, $BooksTable, Book> {
  $$BooksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BookNamesTable, List<BookName>>
  _bookNamesRefsTable(_$BibleDatabase db) => MultiTypedResultKey.fromTable(
    db.bookNames,
    aliasName: 'books__id__book_names__book_id',
  );

  $$BookNamesTableProcessedTableManager get bookNamesRefs {
    final manager = $$BookNamesTableTableManager(
      $_db,
      $_db.bookNames,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookNamesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VersesTable, List<Verse>> _versesRefsTable(
    _$BibleDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.verses,
    aliasName: 'books__id__verses__book_id',
  );

  $$VersesTableProcessedTableManager get versesRefs {
    final manager = $$VersesTableTableManager(
      $_db,
      $_db.verses,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_versesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ParallelRowsTable, List<ParallelRow>>
  _parallelRowsRefsTable(_$BibleDatabase db) => MultiTypedResultKey.fromTable(
    db.parallelRows,
    aliasName: 'books__id__parallel_rows__book_id',
  );

  $$ParallelRowsTableProcessedTableManager get parallelRowsRefs {
    final manager = $$ParallelRowsTableTableManager(
      $_db,
      $_db.parallelRows,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_parallelRowsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BooksTableFilterComposer
    extends Composer<_$BibleDatabase, $BooksTable> {
  $$BooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get testament => $composableBuilder(
    column: $table.testament,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapterCount => $composableBuilder(
    column: $table.chapterCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get osisCode => $composableBuilder(
    column: $table.osisCode,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> bookNamesRefs(
    Expression<bool> Function($$BookNamesTableFilterComposer f) f,
  ) {
    final $$BookNamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookNames,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookNamesTableFilterComposer(
            $db: $db,
            $table: $db.bookNames,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> versesRefs(
    Expression<bool> Function($$VersesTableFilterComposer f) f,
  ) {
    final $$VersesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.verses,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VersesTableFilterComposer(
            $db: $db,
            $table: $db.verses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> parallelRowsRefs(
    Expression<bool> Function($$ParallelRowsTableFilterComposer f) f,
  ) {
    final $$ParallelRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.parallelRows,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ParallelRowsTableFilterComposer(
            $db: $db,
            $table: $db.parallelRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BooksTableOrderingComposer
    extends Composer<_$BibleDatabase, $BooksTable> {
  $$BooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get testament => $composableBuilder(
    column: $table.testament,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapterCount => $composableBuilder(
    column: $table.chapterCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get osisCode => $composableBuilder(
    column: $table.osisCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BooksTableAnnotationComposer
    extends Composer<_$BibleDatabase, $BooksTable> {
  $$BooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get testament =>
      $composableBuilder(column: $table.testament, builder: (column) => column);

  GeneratedColumn<int> get chapterCount => $composableBuilder(
    column: $table.chapterCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get osisCode =>
      $composableBuilder(column: $table.osisCode, builder: (column) => column);

  Expression<T> bookNamesRefs<T extends Object>(
    Expression<T> Function($$BookNamesTableAnnotationComposer a) f,
  ) {
    final $$BookNamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookNames,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookNamesTableAnnotationComposer(
            $db: $db,
            $table: $db.bookNames,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> versesRefs<T extends Object>(
    Expression<T> Function($$VersesTableAnnotationComposer a) f,
  ) {
    final $$VersesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.verses,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VersesTableAnnotationComposer(
            $db: $db,
            $table: $db.verses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> parallelRowsRefs<T extends Object>(
    Expression<T> Function($$ParallelRowsTableAnnotationComposer a) f,
  ) {
    final $$ParallelRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.parallelRows,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ParallelRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.parallelRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BooksTableTableManager
    extends
        RootTableManager<
          _$BibleDatabase,
          $BooksTable,
          Book,
          $$BooksTableFilterComposer,
          $$BooksTableOrderingComposer,
          $$BooksTableAnnotationComposer,
          $$BooksTableCreateCompanionBuilder,
          $$BooksTableUpdateCompanionBuilder,
          (Book, $$BooksTableReferences),
          Book,
          PrefetchHooks Function({
            bool bookNamesRefs,
            bool versesRefs,
            bool parallelRowsRefs,
          })
        > {
  $$BooksTableTableManager(_$BibleDatabase db, $BooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> testament = const Value.absent(),
                Value<int> chapterCount = const Value.absent(),
                Value<String> osisCode = const Value.absent(),
              }) => BooksCompanion(
                id: id,
                testament: testament,
                chapterCount: chapterCount,
                osisCode: osisCode,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String testament,
                required int chapterCount,
                required String osisCode,
              }) => BooksCompanion.insert(
                id: id,
                testament: testament,
                chapterCount: chapterCount,
                osisCode: osisCode,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BooksTable, Book>(table),
                  $$BooksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                bookNamesRefs = false,
                versesRefs = false,
                parallelRowsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (bookNamesRefs) db.bookNames,
                    if (versesRefs) db.verses,
                    if (parallelRowsRefs) db.parallelRows,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (bookNamesRefs)
                        await $_getPrefetchedData<Book, $BooksTable, BookName>(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._bookNamesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).bookNamesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (versesRefs)
                        await $_getPrefetchedData<Book, $BooksTable, Verse>(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._versesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(db, table, p0).versesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (parallelRowsRefs)
                        await $_getPrefetchedData<
                          Book,
                          $BooksTable,
                          ParallelRow
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._parallelRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).parallelRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BooksTableProcessedTableManager =
    ProcessedTableManager<
      _$BibleDatabase,
      $BooksTable,
      Book,
      $$BooksTableFilterComposer,
      $$BooksTableOrderingComposer,
      $$BooksTableAnnotationComposer,
      $$BooksTableCreateCompanionBuilder,
      $$BooksTableUpdateCompanionBuilder,
      (Book, $$BooksTableReferences),
      Book,
      PrefetchHooks Function({
        bool bookNamesRefs,
        bool versesRefs,
        bool parallelRowsRefs,
      })
    >;
typedef $$BookNamesTableCreateCompanionBuilder = BookNamesCompanion Function({
  required int bookId,
  required String translationId,
  required String name,
  required String shortName,
  Value<int> rowid,
});
typedef $$BookNamesTableUpdateCompanionBuilder = BookNamesCompanion Function({
  Value<int> bookId,
  Value<String> translationId,
  Value<String> name,
  Value<String> shortName,
  Value<int> rowid,
});

final class $$BookNamesTableReferences
    extends BaseReferences<_$BibleDatabase, $BookNamesTable, BookName> {
  $$BookNamesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$BibleDatabase db) =>
      db.books.createAlias('book_names__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TranslationsTable _translationIdTable(_$BibleDatabase db) => db
      .translations
      .createAlias('book_names__translation_id__translations__id');

  $$TranslationsTableProcessedTableManager get translationId {
    final $_column = $_itemColumn<String>('translation_id')!;

    final manager = $$TranslationsTableTableManager(
      $_db,
      $_db.translations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_translationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BookNamesTableFilterComposer
    extends Composer<_$BibleDatabase, $BookNamesTable> {
  $$BookNamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shortName => $composableBuilder(
    column: $table.shortName,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TranslationsTableFilterComposer get translationId {
    final $$TranslationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.translationId,
      referencedTable: $db.translations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TranslationsTableFilterComposer(
            $db: $db,
            $table: $db.translations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookNamesTableOrderingComposer
    extends Composer<_$BibleDatabase, $BookNamesTable> {
  $$BookNamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shortName => $composableBuilder(
    column: $table.shortName,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TranslationsTableOrderingComposer get translationId {
    final $$TranslationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.translationId,
      referencedTable: $db.translations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TranslationsTableOrderingComposer(
            $db: $db,
            $table: $db.translations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookNamesTableAnnotationComposer
    extends Composer<_$BibleDatabase, $BookNamesTable> {
  $$BookNamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get shortName =>
      $composableBuilder(column: $table.shortName, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TranslationsTableAnnotationComposer get translationId {
    final $$TranslationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.translationId,
      referencedTable: $db.translations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TranslationsTableAnnotationComposer(
            $db: $db,
            $table: $db.translations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookNamesTableTableManager
    extends
        RootTableManager<
          _$BibleDatabase,
          $BookNamesTable,
          BookName,
          $$BookNamesTableFilterComposer,
          $$BookNamesTableOrderingComposer,
          $$BookNamesTableAnnotationComposer,
          $$BookNamesTableCreateCompanionBuilder,
          $$BookNamesTableUpdateCompanionBuilder,
          (BookName, $$BookNamesTableReferences),
          BookName,
          PrefetchHooks Function({bool bookId, bool translationId})
        > {
  $$BookNamesTableTableManager(_$BibleDatabase db, $BookNamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookNamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookNamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookNamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> bookId = const Value.absent(),
                Value<String> translationId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> shortName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookNamesCompanion(
                bookId: bookId,
                translationId: translationId,
                name: name,
                shortName: shortName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int bookId,
                required String translationId,
                required String name,
                required String shortName,
                Value<int> rowid = const Value.absent(),
              }) => BookNamesCompanion.insert(
                bookId: bookId,
                translationId: translationId,
                name: name,
                shortName: shortName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookNamesTable, BookName>(table),
                  $$BookNamesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false, translationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bookId,
                        referencedTable: $$BookNamesTableReferences
                            ._bookIdTable(db),
                        referencedColumn: $$BookNamesTableReferences
                            ._bookIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (translationId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.translationId,
                        referencedTable: $$BookNamesTableReferences
                            ._translationIdTable(db),
                        referencedColumn: $$BookNamesTableReferences
                            ._translationIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BookNamesTableProcessedTableManager =
    ProcessedTableManager<
      _$BibleDatabase,
      $BookNamesTable,
      BookName,
      $$BookNamesTableFilterComposer,
      $$BookNamesTableOrderingComposer,
      $$BookNamesTableAnnotationComposer,
      $$BookNamesTableCreateCompanionBuilder,
      $$BookNamesTableUpdateCompanionBuilder,
      (BookName, $$BookNamesTableReferences),
      BookName,
      PrefetchHooks Function({bool bookId, bool translationId})
    >;
typedef $$VersesTableCreateCompanionBuilder = VersesCompanion Function({
  required String translationId,
  required int bookId,
  required int chapter,
  required int verse,
  required String verseText,
  required String textFolded,
  Value<String?> heading,
  Value<String?> crossRef,
  Value<int> rowid,
});
typedef $$VersesTableUpdateCompanionBuilder = VersesCompanion Function({
  Value<String> translationId,
  Value<int> bookId,
  Value<int> chapter,
  Value<int> verse,
  Value<String> verseText,
  Value<String> textFolded,
  Value<String?> heading,
  Value<String?> crossRef,
  Value<int> rowid,
});

final class $$VersesTableReferences
    extends BaseReferences<_$BibleDatabase, $VersesTable, Verse> {
  $$VersesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TranslationsTable _translationIdTable(_$BibleDatabase db) =>
      db.translations.createAlias('verses__translation_id__translations__id');

  $$TranslationsTableProcessedTableManager get translationId {
    final $_column = $_itemColumn<String>('translation_id')!;

    final manager = $$TranslationsTableTableManager(
      $_db,
      $_db.translations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_translationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BooksTable _bookIdTable(_$BibleDatabase db) =>
      db.books.createAlias('verses__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VersesTableFilterComposer
    extends Composer<_$BibleDatabase, $VersesTable> {
  $$VersesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get verse => $composableBuilder(
    column: $table.verse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verseText => $composableBuilder(
    column: $table.verseText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textFolded => $composableBuilder(
    column: $table.textFolded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get heading => $composableBuilder(
    column: $table.heading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crossRef => $composableBuilder(
    column: $table.crossRef,
    builder: (column) => ColumnFilters(column),
  );

  $$TranslationsTableFilterComposer get translationId {
    final $$TranslationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.translationId,
      referencedTable: $db.translations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TranslationsTableFilterComposer(
            $db: $db,
            $table: $db.translations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VersesTableOrderingComposer
    extends Composer<_$BibleDatabase, $VersesTable> {
  $$VersesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verse => $composableBuilder(
    column: $table.verse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verseText => $composableBuilder(
    column: $table.verseText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textFolded => $composableBuilder(
    column: $table.textFolded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heading => $composableBuilder(
    column: $table.heading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crossRef => $composableBuilder(
    column: $table.crossRef,
    builder: (column) => ColumnOrderings(column),
  );

  $$TranslationsTableOrderingComposer get translationId {
    final $$TranslationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.translationId,
      referencedTable: $db.translations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TranslationsTableOrderingComposer(
            $db: $db,
            $table: $db.translations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VersesTableAnnotationComposer
    extends Composer<_$BibleDatabase, $VersesTable> {
  $$VersesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get verse =>
      $composableBuilder(column: $table.verse, builder: (column) => column);

  GeneratedColumn<String> get verseText =>
      $composableBuilder(column: $table.verseText, builder: (column) => column);

  GeneratedColumn<String> get textFolded => $composableBuilder(
    column: $table.textFolded,
    builder: (column) => column,
  );

  GeneratedColumn<String> get heading =>
      $composableBuilder(column: $table.heading, builder: (column) => column);

  GeneratedColumn<String> get crossRef =>
      $composableBuilder(column: $table.crossRef, builder: (column) => column);

  $$TranslationsTableAnnotationComposer get translationId {
    final $$TranslationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.translationId,
      referencedTable: $db.translations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TranslationsTableAnnotationComposer(
            $db: $db,
            $table: $db.translations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VersesTableTableManager
    extends
        RootTableManager<
          _$BibleDatabase,
          $VersesTable,
          Verse,
          $$VersesTableFilterComposer,
          $$VersesTableOrderingComposer,
          $$VersesTableAnnotationComposer,
          $$VersesTableCreateCompanionBuilder,
          $$VersesTableUpdateCompanionBuilder,
          (Verse, $$VersesTableReferences),
          Verse,
          PrefetchHooks Function({bool translationId, bool bookId})
        > {
  $$VersesTableTableManager(_$BibleDatabase db, $VersesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VersesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VersesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VersesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> translationId = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<int> verse = const Value.absent(),
                Value<String> verseText = const Value.absent(),
                Value<String> textFolded = const Value.absent(),
                Value<String?> heading = const Value.absent(),
                Value<String?> crossRef = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VersesCompanion(
                translationId: translationId,
                bookId: bookId,
                chapter: chapter,
                verse: verse,
                verseText: verseText,
                textFolded: textFolded,
                heading: heading,
                crossRef: crossRef,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String translationId,
                required int bookId,
                required int chapter,
                required int verse,
                required String verseText,
                required String textFolded,
                Value<String?> heading = const Value.absent(),
                Value<String?> crossRef = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VersesCompanion.insert(
                translationId: translationId,
                bookId: bookId,
                chapter: chapter,
                verse: verse,
                verseText: verseText,
                textFolded: textFolded,
                heading: heading,
                crossRef: crossRef,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VersesTable, Verse>(table),
                  $$VersesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({translationId = false, bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (translationId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.translationId,
                        referencedTable: $$VersesTableReferences
                            ._translationIdTable(db),
                        referencedColumn: $$VersesTableReferences
                            ._translationIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (bookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bookId,
                        referencedTable: $$VersesTableReferences._bookIdTable(
                          db,
                        ),
                        referencedColumn: $$VersesTableReferences
                            ._bookIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VersesTableProcessedTableManager =
    ProcessedTableManager<
      _$BibleDatabase,
      $VersesTable,
      Verse,
      $$VersesTableFilterComposer,
      $$VersesTableOrderingComposer,
      $$VersesTableAnnotationComposer,
      $$VersesTableCreateCompanionBuilder,
      $$VersesTableUpdateCompanionBuilder,
      (Verse, $$VersesTableReferences),
      Verse,
      PrefetchHooks Function({bool translationId, bool bookId})
    >;
typedef $$ParallelRowsTableCreateCompanionBuilder =
    ParallelRowsCompanion Function({
      required String pairId,
      required int bookId,
      required int chapter,
      required int rowIndex,
      required String label,
      Value<int?> aStart,
      Value<int?> aEnd,
      Value<int?> bStart,
      Value<int?> bEnd,
      Value<int> rowid,
    });
typedef $$ParallelRowsTableUpdateCompanionBuilder =
    ParallelRowsCompanion Function({
      Value<String> pairId,
      Value<int> bookId,
      Value<int> chapter,
      Value<int> rowIndex,
      Value<String> label,
      Value<int?> aStart,
      Value<int?> aEnd,
      Value<int?> bStart,
      Value<int?> bEnd,
      Value<int> rowid,
    });

final class $$ParallelRowsTableReferences
    extends BaseReferences<_$BibleDatabase, $ParallelRowsTable, ParallelRow> {
  $$ParallelRowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$BibleDatabase db) =>
      db.books.createAlias('parallel_rows__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ParallelRowsTableFilterComposer
    extends Composer<_$BibleDatabase, $ParallelRowsTable> {
  $$ParallelRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pairId => $composableBuilder(
    column: $table.pairId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowIndex => $composableBuilder(
    column: $table.rowIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get aStart => $composableBuilder(
    column: $table.aStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get aEnd => $composableBuilder(
    column: $table.aEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bStart => $composableBuilder(
    column: $table.bStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bEnd => $composableBuilder(
    column: $table.bEnd,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ParallelRowsTableOrderingComposer
    extends Composer<_$BibleDatabase, $ParallelRowsTable> {
  $$ParallelRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pairId => $composableBuilder(
    column: $table.pairId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowIndex => $composableBuilder(
    column: $table.rowIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get aStart => $composableBuilder(
    column: $table.aStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get aEnd => $composableBuilder(
    column: $table.aEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bStart => $composableBuilder(
    column: $table.bStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bEnd => $composableBuilder(
    column: $table.bEnd,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ParallelRowsTableAnnotationComposer
    extends Composer<_$BibleDatabase, $ParallelRowsTable> {
  $$ParallelRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pairId =>
      $composableBuilder(column: $table.pairId, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get rowIndex =>
      $composableBuilder(column: $table.rowIndex, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get aStart =>
      $composableBuilder(column: $table.aStart, builder: (column) => column);

  GeneratedColumn<int> get aEnd =>
      $composableBuilder(column: $table.aEnd, builder: (column) => column);

  GeneratedColumn<int> get bStart =>
      $composableBuilder(column: $table.bStart, builder: (column) => column);

  GeneratedColumn<int> get bEnd =>
      $composableBuilder(column: $table.bEnd, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ParallelRowsTableTableManager
    extends
        RootTableManager<
          _$BibleDatabase,
          $ParallelRowsTable,
          ParallelRow,
          $$ParallelRowsTableFilterComposer,
          $$ParallelRowsTableOrderingComposer,
          $$ParallelRowsTableAnnotationComposer,
          $$ParallelRowsTableCreateCompanionBuilder,
          $$ParallelRowsTableUpdateCompanionBuilder,
          (ParallelRow, $$ParallelRowsTableReferences),
          ParallelRow,
          PrefetchHooks Function({bool bookId})
        > {
  $$ParallelRowsTableTableManager(_$BibleDatabase db, $ParallelRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ParallelRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ParallelRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ParallelRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> pairId = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<int> rowIndex = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int?> aStart = const Value.absent(),
                Value<int?> aEnd = const Value.absent(),
                Value<int?> bStart = const Value.absent(),
                Value<int?> bEnd = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ParallelRowsCompanion(
                pairId: pairId,
                bookId: bookId,
                chapter: chapter,
                rowIndex: rowIndex,
                label: label,
                aStart: aStart,
                aEnd: aEnd,
                bStart: bStart,
                bEnd: bEnd,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String pairId,
                required int bookId,
                required int chapter,
                required int rowIndex,
                required String label,
                Value<int?> aStart = const Value.absent(),
                Value<int?> aEnd = const Value.absent(),
                Value<int?> bStart = const Value.absent(),
                Value<int?> bEnd = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ParallelRowsCompanion.insert(
                pairId: pairId,
                bookId: bookId,
                chapter: chapter,
                rowIndex: rowIndex,
                label: label,
                aStart: aStart,
                aEnd: aEnd,
                bStart: bStart,
                bEnd: bEnd,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ParallelRowsTable, ParallelRow>(table),
                  $$ParallelRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bookId,
                        referencedTable: $$ParallelRowsTableReferences
                            ._bookIdTable(db),
                        referencedColumn: $$ParallelRowsTableReferences
                            ._bookIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ParallelRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$BibleDatabase,
      $ParallelRowsTable,
      ParallelRow,
      $$ParallelRowsTableFilterComposer,
      $$ParallelRowsTableOrderingComposer,
      $$ParallelRowsTableAnnotationComposer,
      $$ParallelRowsTableCreateCompanionBuilder,
      $$ParallelRowsTableUpdateCompanionBuilder,
      (ParallelRow, $$ParallelRowsTableReferences),
      ParallelRow,
      PrefetchHooks Function({bool bookId})
    >;

class $BibleDatabaseManager {
  final _$BibleDatabase _db;
  $BibleDatabaseManager(this._db);
  $$TranslationsTableTableManager get translations =>
      $$TranslationsTableTableManager(_db, _db.translations);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
  $$BookNamesTableTableManager get bookNames =>
      $$BookNamesTableTableManager(_db, _db.bookNames);
  $$VersesTableTableManager get verses =>
      $$VersesTableTableManager(_db, _db.verses);
  $$ParallelRowsTableTableManager get parallelRows =>
      $$ParallelRowsTableTableManager(_db, _db.parallelRows);
}
