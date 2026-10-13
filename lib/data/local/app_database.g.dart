// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CardsTableTable extends CardsTable
    with TableInfo<$CardsTableTable, Cards> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _aboutMeta = const VerificationMeta('about');
  @override
  late final GeneratedColumn<String> about = GeneratedColumn<String>(
    'about',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageMeta = const VerificationMeta('image');
  @override
  late final GeneratedColumn<String> image = GeneratedColumn<String>(
    'image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeTypeMeta = const VerificationMeta(
    'codeType',
  );
  @override
  late final GeneratedColumn<String> codeType = GeneratedColumn<String>(
    'code_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('code128'),
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _pendingDeleteMeta = const VerificationMeta(
    'pendingDelete',
  );
  @override
  late final GeneratedColumn<bool> pendingDelete = GeneratedColumn<bool>(
    'pending_delete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_delete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    name,
    about,
    barcode,
    image,
    codeType,
    isDirty,
    pendingDelete,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cards> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('about')) {
      context.handle(
        _aboutMeta,
        about.isAcceptableOrUnknown(data['about']!, _aboutMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    } else if (isInserting) {
      context.missing(_barcodeMeta);
    }
    if (data.containsKey('image')) {
      context.handle(
        _imageMeta,
        image.isAcceptableOrUnknown(data['image']!, _imageMeta),
      );
    }
    if (data.containsKey('code_type')) {
      context.handle(
        _codeTypeMeta,
        codeType.isAcceptableOrUnknown(data['code_type']!, _codeTypeMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('pending_delete')) {
      context.handle(
        _pendingDeleteMeta,
        pendingDelete.isAcceptableOrUnknown(
          data['pending_delete']!,
          _pendingDeleteMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cards map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cards(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      about: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}about'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      )!,
      image: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image'],
      ),
      codeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code_type'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      pendingDelete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_delete'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CardsTableTable createAlias(String alias) {
    return $CardsTableTable(attachedDatabase, alias);
  }
}

class Cards extends DataClass implements Insertable<Cards> {
  final int id;
  final String? serverId;
  final String name;
  final String? about;
  final String barcode;
  final String? image;
  final String codeType;
  final bool isDirty;
  final bool pendingDelete;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Cards({
    required this.id,
    this.serverId,
    required this.name,
    this.about,
    required this.barcode,
    this.image,
    required this.codeType,
    required this.isDirty,
    required this.pendingDelete,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || about != null) {
      map['about'] = Variable<String>(about);
    }
    map['barcode'] = Variable<String>(barcode);
    if (!nullToAbsent || image != null) {
      map['image'] = Variable<String>(image);
    }
    map['code_type'] = Variable<String>(codeType);
    map['is_dirty'] = Variable<bool>(isDirty);
    map['pending_delete'] = Variable<bool>(pendingDelete);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CardsTableCompanion toCompanion(bool nullToAbsent) {
    return CardsTableCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      name: Value(name),
      about: about == null && nullToAbsent
          ? const Value.absent()
          : Value(about),
      barcode: Value(barcode),
      image: image == null && nullToAbsent
          ? const Value.absent()
          : Value(image),
      codeType: Value(codeType),
      isDirty: Value(isDirty),
      pendingDelete: Value(pendingDelete),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Cards.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cards(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      name: serializer.fromJson<String>(json['name']),
      about: serializer.fromJson<String?>(json['about']),
      barcode: serializer.fromJson<String>(json['barcode']),
      image: serializer.fromJson<String?>(json['image']),
      codeType: serializer.fromJson<String>(json['codeType']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      pendingDelete: serializer.fromJson<bool>(json['pendingDelete']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'name': serializer.toJson<String>(name),
      'about': serializer.toJson<String?>(about),
      'barcode': serializer.toJson<String>(barcode),
      'image': serializer.toJson<String?>(image),
      'codeType': serializer.toJson<String>(codeType),
      'isDirty': serializer.toJson<bool>(isDirty),
      'pendingDelete': serializer.toJson<bool>(pendingDelete),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Cards copyWith({
    int? id,
    Value<String?> serverId = const Value.absent(),
    String? name,
    Value<String?> about = const Value.absent(),
    String? barcode,
    Value<String?> image = const Value.absent(),
    String? codeType,
    bool? isDirty,
    bool? pendingDelete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Cards(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    name: name ?? this.name,
    about: about.present ? about.value : this.about,
    barcode: barcode ?? this.barcode,
    image: image.present ? image.value : this.image,
    codeType: codeType ?? this.codeType,
    isDirty: isDirty ?? this.isDirty,
    pendingDelete: pendingDelete ?? this.pendingDelete,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Cards copyWithCompanion(CardsTableCompanion data) {
    return Cards(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      name: data.name.present ? data.name.value : this.name,
      about: data.about.present ? data.about.value : this.about,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      image: data.image.present ? data.image.value : this.image,
      codeType: data.codeType.present ? data.codeType.value : this.codeType,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      pendingDelete: data.pendingDelete.present
          ? data.pendingDelete.value
          : this.pendingDelete,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cards(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('about: $about, ')
          ..write('barcode: $barcode, ')
          ..write('image: $image, ')
          ..write('codeType: $codeType, ')
          ..write('isDirty: $isDirty, ')
          ..write('pendingDelete: $pendingDelete, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    name,
    about,
    barcode,
    image,
    codeType,
    isDirty,
    pendingDelete,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cards &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.name == this.name &&
          other.about == this.about &&
          other.barcode == this.barcode &&
          other.image == this.image &&
          other.codeType == this.codeType &&
          other.isDirty == this.isDirty &&
          other.pendingDelete == this.pendingDelete &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CardsTableCompanion extends UpdateCompanion<Cards> {
  final Value<int> id;
  final Value<String?> serverId;
  final Value<String> name;
  final Value<String?> about;
  final Value<String> barcode;
  final Value<String?> image;
  final Value<String> codeType;
  final Value<bool> isDirty;
  final Value<bool> pendingDelete;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CardsTableCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.name = const Value.absent(),
    this.about = const Value.absent(),
    this.barcode = const Value.absent(),
    this.image = const Value.absent(),
    this.codeType = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.pendingDelete = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CardsTableCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String name,
    this.about = const Value.absent(),
    required String barcode,
    this.image = const Value.absent(),
    this.codeType = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.pendingDelete = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       barcode = Value(barcode);
  static Insertable<Cards> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? name,
    Expression<String>? about,
    Expression<String>? barcode,
    Expression<String>? image,
    Expression<String>? codeType,
    Expression<bool>? isDirty,
    Expression<bool>? pendingDelete,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (name != null) 'name': name,
      if (about != null) 'about': about,
      if (barcode != null) 'barcode': barcode,
      if (image != null) 'image': image,
      if (codeType != null) 'code_type': codeType,
      if (isDirty != null) 'is_dirty': isDirty,
      if (pendingDelete != null) 'pending_delete': pendingDelete,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CardsTableCompanion copyWith({
    Value<int>? id,
    Value<String?>? serverId,
    Value<String>? name,
    Value<String?>? about,
    Value<String>? barcode,
    Value<String?>? image,
    Value<String>? codeType,
    Value<bool>? isDirty,
    Value<bool>? pendingDelete,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CardsTableCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      about: about ?? this.about,
      barcode: barcode ?? this.barcode,
      image: image ?? this.image,
      codeType: codeType ?? this.codeType,
      isDirty: isDirty ?? this.isDirty,
      pendingDelete: pendingDelete ?? this.pendingDelete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (about.present) {
      map['about'] = Variable<String>(about.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (image.present) {
      map['image'] = Variable<String>(image.value);
    }
    if (codeType.present) {
      map['code_type'] = Variable<String>(codeType.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (pendingDelete.present) {
      map['pending_delete'] = Variable<bool>(pendingDelete.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsTableCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('about: $about, ')
          ..write('barcode: $barcode, ')
          ..write('image: $image, ')
          ..write('codeType: $codeType, ')
          ..write('isDirty: $isDirty, ')
          ..write('pendingDelete: $pendingDelete, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CardsTableTable cardsTable = $CardsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [cardsTable];
}

typedef $$CardsTableTableCreateCompanionBuilder = CardsTableCompanion Function({
  Value<int> id,
  Value<String?> serverId,
  required String name,
  Value<String?> about,
  required String barcode,
  Value<String?> image,
  Value<String> codeType,
  Value<bool> isDirty,
  Value<bool> pendingDelete,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$CardsTableTableUpdateCompanionBuilder = CardsTableCompanion Function({
  Value<int> id,
  Value<String?> serverId,
  Value<String> name,
  Value<String?> about,
  Value<String> barcode,
  Value<String?> image,
  Value<String> codeType,
  Value<bool> isDirty,
  Value<bool> pendingDelete,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$CardsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CardsTableTable> {
  $$CardsTableTableFilterComposer({
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

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get about => $composableBuilder(
    column: $table.about,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get image => $composableBuilder(
    column: $table.image,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codeType => $composableBuilder(
    column: $table.codeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingDelete => $composableBuilder(
    column: $table.pendingDelete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CardsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CardsTableTable> {
  $$CardsTableTableOrderingComposer({
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

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get about => $composableBuilder(
    column: $table.about,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get image => $composableBuilder(
    column: $table.image,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codeType => $composableBuilder(
    column: $table.codeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingDelete => $composableBuilder(
    column: $table.pendingDelete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CardsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardsTableTable> {
  $$CardsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get about =>
      $composableBuilder(column: $table.about, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get image =>
      $composableBuilder(column: $table.image, builder: (column) => column);

  GeneratedColumn<String> get codeType =>
      $composableBuilder(column: $table.codeType, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<bool> get pendingDelete => $composableBuilder(
    column: $table.pendingDelete,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CardsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CardsTableTable,
          Cards,
          $$CardsTableTableFilterComposer,
          $$CardsTableTableOrderingComposer,
          $$CardsTableTableAnnotationComposer,
          $$CardsTableTableCreateCompanionBuilder,
          $$CardsTableTableUpdateCompanionBuilder,
          (Cards, BaseReferences<_$AppDatabase, $CardsTableTable, Cards>),
          Cards,
          PrefetchHooks Function()
        > {
  $$CardsTableTableTableManager(_$AppDatabase db, $CardsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> about = const Value.absent(),
                Value<String> barcode = const Value.absent(),
                Value<String?> image = const Value.absent(),
                Value<String> codeType = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<bool> pendingDelete = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CardsTableCompanion(
                id: id,
                serverId: serverId,
                name: name,
                about: about,
                barcode: barcode,
                image: image,
                codeType: codeType,
                isDirty: isDirty,
                pendingDelete: pendingDelete,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                required String name,
                Value<String?> about = const Value.absent(),
                required String barcode,
                Value<String?> image = const Value.absent(),
                Value<String> codeType = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<bool> pendingDelete = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CardsTableCompanion.insert(
                id: id,
                serverId: serverId,
                name: name,
                about: about,
                barcode: barcode,
                image: image,
                codeType: codeType,
                isDirty: isDirty,
                pendingDelete: pendingDelete,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CardsTableTable, Cards>(table),
                  BaseReferences<_$AppDatabase, $CardsTableTable, Cards>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CardsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CardsTableTable,
      Cards,
      $$CardsTableTableFilterComposer,
      $$CardsTableTableOrderingComposer,
      $$CardsTableTableAnnotationComposer,
      $$CardsTableTableCreateCompanionBuilder,
      $$CardsTableTableUpdateCompanionBuilder,
      (Cards, BaseReferences<_$AppDatabase, $CardsTableTable, Cards>),
      Cards,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CardsTableTableTableManager get cardsTable =>
      $$CardsTableTableTableManager(_db, _db.cardsTable);
}
