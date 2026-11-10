// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, TaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('autre'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderBeforeMinMeta = const VerificationMeta(
    'reminderBeforeMin',
  );
  @override
  late final GeneratedColumn<int> reminderBeforeMin = GeneratedColumn<int>(
    'reminder_before_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('todo'),
  );
  static const VerificationMeta _shiftedMeta = const VerificationMeta(
    'shifted',
  );
  @override
  late final GeneratedColumn<bool> shifted = GeneratedColumn<bool>(
    'shifted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("shifted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _originalStartTimeMeta = const VerificationMeta(
    'originalStartTime',
  );
  @override
  late final GeneratedColumn<String> originalStartTime =
      GeneratedColumn<String>(
        'original_start_time',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _importBatchIdMeta = const VerificationMeta(
    'importBatchId',
  );
  @override
  late final GeneratedColumn<String> importBatchId = GeneratedColumn<String>(
    'import_batch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendingSyncMeta = const VerificationMeta(
    'pendingSync',
  );
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
    'pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    date,
    startTime,
    endTime,
    categoryId,
    notes,
    reminderBeforeMin,
    status,
    shifted,
    originalStartTime,
    source,
    importBatchId,
    createdAt,
    updatedAt,
    deletedAt,
    pendingSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('reminder_before_min')) {
      context.handle(
        _reminderBeforeMinMeta,
        reminderBeforeMin.isAcceptableOrUnknown(
          data['reminder_before_min']!,
          _reminderBeforeMinMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('shifted')) {
      context.handle(
        _shiftedMeta,
        shifted.isAcceptableOrUnknown(data['shifted']!, _shiftedMeta),
      );
    }
    if (data.containsKey('original_start_time')) {
      context.handle(
        _originalStartTimeMeta,
        originalStartTime.isAcceptableOrUnknown(
          data['original_start_time']!,
          _originalStartTimeMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('import_batch_id')) {
      context.handle(
        _importBatchIdMeta,
        importBatchId.isAcceptableOrUnknown(
          data['import_batch_id']!,
          _importBatchIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
        _pendingSyncMeta,
        pendingSync.isAcceptableOrUnknown(
          data['pending_sync']!,
          _pendingSyncMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      reminderBeforeMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_before_min'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      shifted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}shifted'],
      )!,
      originalStartTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_start_time'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      importBatchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}import_batch_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      pendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_sync'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class TaskRow extends DataClass implements Insertable<TaskRow> {
  final String id;
  final String title;
  final String date;
  final String startTime;
  final String endTime;
  final String categoryId;
  final String? notes;
  final int? reminderBeforeMin;
  final String status;
  final bool shifted;
  final String? originalStartTime;
  final String source;
  final String? importBatchId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Vrai tant que la dernière écriture locale n'a pas été envoyée au serveur.
  final bool pendingSync;
  const TaskRow({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.categoryId,
    this.notes,
    this.reminderBeforeMin,
    required this.status,
    required this.shifted,
    this.originalStartTime,
    required this.source,
    this.importBatchId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.pendingSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['date'] = Variable<String>(date);
    map['start_time'] = Variable<String>(startTime);
    map['end_time'] = Variable<String>(endTime);
    map['category_id'] = Variable<String>(categoryId);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || reminderBeforeMin != null) {
      map['reminder_before_min'] = Variable<int>(reminderBeforeMin);
    }
    map['status'] = Variable<String>(status);
    map['shifted'] = Variable<bool>(shifted);
    if (!nullToAbsent || originalStartTime != null) {
      map['original_start_time'] = Variable<String>(originalStartTime);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || importBatchId != null) {
      map['import_batch_id'] = Variable<String>(importBatchId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['pending_sync'] = Variable<bool>(pendingSync);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      date: Value(date),
      startTime: Value(startTime),
      endTime: Value(endTime),
      categoryId: Value(categoryId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      reminderBeforeMin: reminderBeforeMin == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderBeforeMin),
      status: Value(status),
      shifted: Value(shifted),
      originalStartTime: originalStartTime == null && nullToAbsent
          ? const Value.absent()
          : Value(originalStartTime),
      source: Value(source),
      importBatchId: importBatchId == null && nullToAbsent
          ? const Value.absent()
          : Value(importBatchId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      pendingSync: Value(pendingSync),
    );
  }

  factory TaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      date: serializer.fromJson<String>(json['date']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String>(json['endTime']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      notes: serializer.fromJson<String?>(json['notes']),
      reminderBeforeMin: serializer.fromJson<int?>(json['reminderBeforeMin']),
      status: serializer.fromJson<String>(json['status']),
      shifted: serializer.fromJson<bool>(json['shifted']),
      originalStartTime: serializer.fromJson<String?>(
        json['originalStartTime'],
      ),
      source: serializer.fromJson<String>(json['source']),
      importBatchId: serializer.fromJson<String?>(json['importBatchId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'date': serializer.toJson<String>(date),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String>(endTime),
      'categoryId': serializer.toJson<String>(categoryId),
      'notes': serializer.toJson<String?>(notes),
      'reminderBeforeMin': serializer.toJson<int?>(reminderBeforeMin),
      'status': serializer.toJson<String>(status),
      'shifted': serializer.toJson<bool>(shifted),
      'originalStartTime': serializer.toJson<String?>(originalStartTime),
      'source': serializer.toJson<String>(source),
      'importBatchId': serializer.toJson<String?>(importBatchId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'pendingSync': serializer.toJson<bool>(pendingSync),
    };
  }

  TaskRow copyWith({
    String? id,
    String? title,
    String? date,
    String? startTime,
    String? endTime,
    String? categoryId,
    Value<String?> notes = const Value.absent(),
    Value<int?> reminderBeforeMin = const Value.absent(),
    String? status,
    bool? shifted,
    Value<String?> originalStartTime = const Value.absent(),
    String? source,
    Value<String?> importBatchId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? pendingSync,
  }) => TaskRow(
    id: id ?? this.id,
    title: title ?? this.title,
    date: date ?? this.date,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    categoryId: categoryId ?? this.categoryId,
    notes: notes.present ? notes.value : this.notes,
    reminderBeforeMin: reminderBeforeMin.present
        ? reminderBeforeMin.value
        : this.reminderBeforeMin,
    status: status ?? this.status,
    shifted: shifted ?? this.shifted,
    originalStartTime: originalStartTime.present
        ? originalStartTime.value
        : this.originalStartTime,
    source: source ?? this.source,
    importBatchId: importBatchId.present
        ? importBatchId.value
        : this.importBatchId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    pendingSync: pendingSync ?? this.pendingSync,
  );
  TaskRow copyWithCompanion(TasksCompanion data) {
    return TaskRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      date: data.date.present ? data.date.value : this.date,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      notes: data.notes.present ? data.notes.value : this.notes,
      reminderBeforeMin: data.reminderBeforeMin.present
          ? data.reminderBeforeMin.value
          : this.reminderBeforeMin,
      status: data.status.present ? data.status.value : this.status,
      shifted: data.shifted.present ? data.shifted.value : this.shifted,
      originalStartTime: data.originalStartTime.present
          ? data.originalStartTime.value
          : this.originalStartTime,
      source: data.source.present ? data.source.value : this.source,
      importBatchId: data.importBatchId.present
          ? data.importBatchId.value
          : this.importBatchId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      pendingSync: data.pendingSync.present
          ? data.pendingSync.value
          : this.pendingSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('categoryId: $categoryId, ')
          ..write('notes: $notes, ')
          ..write('reminderBeforeMin: $reminderBeforeMin, ')
          ..write('status: $status, ')
          ..write('shifted: $shifted, ')
          ..write('originalStartTime: $originalStartTime, ')
          ..write('source: $source, ')
          ..write('importBatchId: $importBatchId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    date,
    startTime,
    endTime,
    categoryId,
    notes,
    reminderBeforeMin,
    status,
    shifted,
    originalStartTime,
    source,
    importBatchId,
    createdAt,
    updatedAt,
    deletedAt,
    pendingSync,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.date == this.date &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.categoryId == this.categoryId &&
          other.notes == this.notes &&
          other.reminderBeforeMin == this.reminderBeforeMin &&
          other.status == this.status &&
          other.shifted == this.shifted &&
          other.originalStartTime == this.originalStartTime &&
          other.source == this.source &&
          other.importBatchId == this.importBatchId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.pendingSync == this.pendingSync);
}

class TasksCompanion extends UpdateCompanion<TaskRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> date;
  final Value<String> startTime;
  final Value<String> endTime;
  final Value<String> categoryId;
  final Value<String?> notes;
  final Value<int?> reminderBeforeMin;
  final Value<String> status;
  final Value<bool> shifted;
  final Value<String?> originalStartTime;
  final Value<String> source;
  final Value<String?> importBatchId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> pendingSync;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.date = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.notes = const Value.absent(),
    this.reminderBeforeMin = const Value.absent(),
    this.status = const Value.absent(),
    this.shifted = const Value.absent(),
    this.originalStartTime = const Value.absent(),
    this.source = const Value.absent(),
    this.importBatchId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    required String date,
    required String startTime,
    required String endTime,
    this.categoryId = const Value.absent(),
    this.notes = const Value.absent(),
    this.reminderBeforeMin = const Value.absent(),
    this.status = const Value.absent(),
    this.shifted = const Value.absent(),
    this.originalStartTime = const Value.absent(),
    this.source = const Value.absent(),
    this.importBatchId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       date = Value(date),
       startTime = Value(startTime),
       endTime = Value(endTime),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TaskRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? date,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? categoryId,
    Expression<String>? notes,
    Expression<int>? reminderBeforeMin,
    Expression<String>? status,
    Expression<bool>? shifted,
    Expression<String>? originalStartTime,
    Expression<String>? source,
    Expression<String>? importBatchId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? pendingSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (date != null) 'date': date,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (categoryId != null) 'category_id': categoryId,
      if (notes != null) 'notes': notes,
      if (reminderBeforeMin != null) 'reminder_before_min': reminderBeforeMin,
      if (status != null) 'status': status,
      if (shifted != null) 'shifted': shifted,
      if (originalStartTime != null) 'original_start_time': originalStartTime,
      if (source != null) 'source': source,
      if (importBatchId != null) 'import_batch_id': importBatchId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? date,
    Value<String>? startTime,
    Value<String>? endTime,
    Value<String>? categoryId,
    Value<String?>? notes,
    Value<int?>? reminderBeforeMin,
    Value<String>? status,
    Value<bool>? shifted,
    Value<String?>? originalStartTime,
    Value<String>? source,
    Value<String?>? importBatchId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? pendingSync,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      categoryId: categoryId ?? this.categoryId,
      notes: notes ?? this.notes,
      reminderBeforeMin: reminderBeforeMin ?? this.reminderBeforeMin,
      status: status ?? this.status,
      shifted: shifted ?? this.shifted,
      originalStartTime: originalStartTime ?? this.originalStartTime,
      source: source ?? this.source,
      importBatchId: importBatchId ?? this.importBatchId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (reminderBeforeMin.present) {
      map['reminder_before_min'] = Variable<int>(reminderBeforeMin.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (shifted.present) {
      map['shifted'] = Variable<bool>(shifted.value);
    }
    if (originalStartTime.present) {
      map['original_start_time'] = Variable<String>(originalStartTime.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (importBatchId.present) {
      map['import_batch_id'] = Variable<String>(importBatchId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('categoryId: $categoryId, ')
          ..write('notes: $notes, ')
          ..write('reminderBeforeMin: $reminderBeforeMin, ')
          ..write('status: $status, ')
          ..write('shifted: $shifted, ')
          ..write('originalStartTime: $originalStartTime, ')
          ..write('source: $source, ')
          ..write('importBatchId: $importBatchId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsEntriesTable extends SettingsEntries
    with TableInfo<$SettingsEntriesTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _dayStartMeta = const VerificationMeta(
    'dayStart',
  );
  @override
  late final GeneratedColumn<String> dayStart = GeneratedColumn<String>(
    'day_start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayEndMeta = const VerificationMeta('dayEnd');
  @override
  late final GeneratedColumn<String> dayEnd = GeneratedColumn<String>(
    'day_end',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultReminderMinMeta =
      const VerificationMeta('defaultReminderMin');
  @override
  late final GeneratedColumn<int> defaultReminderMin = GeneratedColumn<int>(
    'default_reminder_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _morningSummaryEnabledMeta =
      const VerificationMeta('morningSummaryEnabled');
  @override
  late final GeneratedColumn<bool> morningSummaryEnabled =
      GeneratedColumn<bool>(
        'morning_summary_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("morning_summary_enabled" IN (0, 1))',
        ),
      );
  static const VerificationMeta _morningSummaryTimeMeta =
      const VerificationMeta('morningSummaryTime');
  @override
  late final GeneratedColumn<String> morningSummaryTime =
      GeneratedColumn<String>(
        'morning_summary_time',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notificationPromptShownMeta =
      const VerificationMeta('notificationPromptShown');
  @override
  late final GeneratedColumn<bool> notificationPromptShown =
      GeneratedColumn<bool>(
        'notification_prompt_shown',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notification_prompt_shown" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _pendingSyncMeta = const VerificationMeta(
    'pendingSync',
  );
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
    'pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dayStart,
    dayEnd,
    timezone,
    defaultReminderMin,
    morningSummaryEnabled,
    morningSummaryTime,
    themeMode,
    updatedAt,
    notificationPromptShown,
    pendingSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_start')) {
      context.handle(
        _dayStartMeta,
        dayStart.isAcceptableOrUnknown(data['day_start']!, _dayStartMeta),
      );
    } else if (isInserting) {
      context.missing(_dayStartMeta);
    }
    if (data.containsKey('day_end')) {
      context.handle(
        _dayEndMeta,
        dayEnd.isAcceptableOrUnknown(data['day_end']!, _dayEndMeta),
      );
    } else if (isInserting) {
      context.missing(_dayEndMeta);
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    } else if (isInserting) {
      context.missing(_timezoneMeta);
    }
    if (data.containsKey('default_reminder_min')) {
      context.handle(
        _defaultReminderMinMeta,
        defaultReminderMin.isAcceptableOrUnknown(
          data['default_reminder_min']!,
          _defaultReminderMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultReminderMinMeta);
    }
    if (data.containsKey('morning_summary_enabled')) {
      context.handle(
        _morningSummaryEnabledMeta,
        morningSummaryEnabled.isAcceptableOrUnknown(
          data['morning_summary_enabled']!,
          _morningSummaryEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_morningSummaryEnabledMeta);
    }
    if (data.containsKey('morning_summary_time')) {
      context.handle(
        _morningSummaryTimeMeta,
        morningSummaryTime.isAcceptableOrUnknown(
          data['morning_summary_time']!,
          _morningSummaryTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_morningSummaryTimeMeta);
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    } else if (isInserting) {
      context.missing(_themeModeMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('notification_prompt_shown')) {
      context.handle(
        _notificationPromptShownMeta,
        notificationPromptShown.isAcceptableOrUnknown(
          data['notification_prompt_shown']!,
          _notificationPromptShownMeta,
        ),
      );
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
        _pendingSyncMeta,
        pendingSync.isAcceptableOrUnknown(
          data['pending_sync']!,
          _pendingSyncMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dayStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_start'],
      )!,
      dayEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_end'],
      )!,
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      defaultReminderMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_reminder_min'],
      )!,
      morningSummaryEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}morning_summary_enabled'],
      )!,
      morningSummaryTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}morning_summary_time'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      notificationPromptShown: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notification_prompt_shown'],
      )!,
      pendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_sync'],
      )!,
    );
  }

  @override
  $SettingsEntriesTable createAlias(String alias) {
    return $SettingsEntriesTable(attachedDatabase, alias);
  }
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final int id;
  final String dayStart;
  final String dayEnd;
  final String timezone;
  final int defaultReminderMin;
  final bool morningSummaryEnabled;
  final String morningSummaryTime;
  final String themeMode;
  final DateTime updatedAt;

  /// Propre à l'appareil : ne fait pas partie des réglages synchronisés.
  final bool notificationPromptShown;
  final bool pendingSync;
  const SettingsRow({
    required this.id,
    required this.dayStart,
    required this.dayEnd,
    required this.timezone,
    required this.defaultReminderMin,
    required this.morningSummaryEnabled,
    required this.morningSummaryTime,
    required this.themeMode,
    required this.updatedAt,
    required this.notificationPromptShown,
    required this.pendingSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day_start'] = Variable<String>(dayStart);
    map['day_end'] = Variable<String>(dayEnd);
    map['timezone'] = Variable<String>(timezone);
    map['default_reminder_min'] = Variable<int>(defaultReminderMin);
    map['morning_summary_enabled'] = Variable<bool>(morningSummaryEnabled);
    map['morning_summary_time'] = Variable<String>(morningSummaryTime);
    map['theme_mode'] = Variable<String>(themeMode);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['notification_prompt_shown'] = Variable<bool>(notificationPromptShown);
    map['pending_sync'] = Variable<bool>(pendingSync);
    return map;
  }

  SettingsEntriesCompanion toCompanion(bool nullToAbsent) {
    return SettingsEntriesCompanion(
      id: Value(id),
      dayStart: Value(dayStart),
      dayEnd: Value(dayEnd),
      timezone: Value(timezone),
      defaultReminderMin: Value(defaultReminderMin),
      morningSummaryEnabled: Value(morningSummaryEnabled),
      morningSummaryTime: Value(morningSummaryTime),
      themeMode: Value(themeMode),
      updatedAt: Value(updatedAt),
      notificationPromptShown: Value(notificationPromptShown),
      pendingSync: Value(pendingSync),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<int>(json['id']),
      dayStart: serializer.fromJson<String>(json['dayStart']),
      dayEnd: serializer.fromJson<String>(json['dayEnd']),
      timezone: serializer.fromJson<String>(json['timezone']),
      defaultReminderMin: serializer.fromJson<int>(json['defaultReminderMin']),
      morningSummaryEnabled: serializer.fromJson<bool>(
        json['morningSummaryEnabled'],
      ),
      morningSummaryTime: serializer.fromJson<String>(
        json['morningSummaryTime'],
      ),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      notificationPromptShown: serializer.fromJson<bool>(
        json['notificationPromptShown'],
      ),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayStart': serializer.toJson<String>(dayStart),
      'dayEnd': serializer.toJson<String>(dayEnd),
      'timezone': serializer.toJson<String>(timezone),
      'defaultReminderMin': serializer.toJson<int>(defaultReminderMin),
      'morningSummaryEnabled': serializer.toJson<bool>(morningSummaryEnabled),
      'morningSummaryTime': serializer.toJson<String>(morningSummaryTime),
      'themeMode': serializer.toJson<String>(themeMode),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'notificationPromptShown': serializer.toJson<bool>(
        notificationPromptShown,
      ),
      'pendingSync': serializer.toJson<bool>(pendingSync),
    };
  }

  SettingsRow copyWith({
    int? id,
    String? dayStart,
    String? dayEnd,
    String? timezone,
    int? defaultReminderMin,
    bool? morningSummaryEnabled,
    String? morningSummaryTime,
    String? themeMode,
    DateTime? updatedAt,
    bool? notificationPromptShown,
    bool? pendingSync,
  }) => SettingsRow(
    id: id ?? this.id,
    dayStart: dayStart ?? this.dayStart,
    dayEnd: dayEnd ?? this.dayEnd,
    timezone: timezone ?? this.timezone,
    defaultReminderMin: defaultReminderMin ?? this.defaultReminderMin,
    morningSummaryEnabled: morningSummaryEnabled ?? this.morningSummaryEnabled,
    morningSummaryTime: morningSummaryTime ?? this.morningSummaryTime,
    themeMode: themeMode ?? this.themeMode,
    updatedAt: updatedAt ?? this.updatedAt,
    notificationPromptShown:
        notificationPromptShown ?? this.notificationPromptShown,
    pendingSync: pendingSync ?? this.pendingSync,
  );
  SettingsRow copyWithCompanion(SettingsEntriesCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      dayStart: data.dayStart.present ? data.dayStart.value : this.dayStart,
      dayEnd: data.dayEnd.present ? data.dayEnd.value : this.dayEnd,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      defaultReminderMin: data.defaultReminderMin.present
          ? data.defaultReminderMin.value
          : this.defaultReminderMin,
      morningSummaryEnabled: data.morningSummaryEnabled.present
          ? data.morningSummaryEnabled.value
          : this.morningSummaryEnabled,
      morningSummaryTime: data.morningSummaryTime.present
          ? data.morningSummaryTime.value
          : this.morningSummaryTime,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      notificationPromptShown: data.notificationPromptShown.present
          ? data.notificationPromptShown.value
          : this.notificationPromptShown,
      pendingSync: data.pendingSync.present
          ? data.pendingSync.value
          : this.pendingSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('dayStart: $dayStart, ')
          ..write('dayEnd: $dayEnd, ')
          ..write('timezone: $timezone, ')
          ..write('defaultReminderMin: $defaultReminderMin, ')
          ..write('morningSummaryEnabled: $morningSummaryEnabled, ')
          ..write('morningSummaryTime: $morningSummaryTime, ')
          ..write('themeMode: $themeMode, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('notificationPromptShown: $notificationPromptShown, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dayStart,
    dayEnd,
    timezone,
    defaultReminderMin,
    morningSummaryEnabled,
    morningSummaryTime,
    themeMode,
    updatedAt,
    notificationPromptShown,
    pendingSync,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.dayStart == this.dayStart &&
          other.dayEnd == this.dayEnd &&
          other.timezone == this.timezone &&
          other.defaultReminderMin == this.defaultReminderMin &&
          other.morningSummaryEnabled == this.morningSummaryEnabled &&
          other.morningSummaryTime == this.morningSummaryTime &&
          other.themeMode == this.themeMode &&
          other.updatedAt == this.updatedAt &&
          other.notificationPromptShown == this.notificationPromptShown &&
          other.pendingSync == this.pendingSync);
}

class SettingsEntriesCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<String> dayStart;
  final Value<String> dayEnd;
  final Value<String> timezone;
  final Value<int> defaultReminderMin;
  final Value<bool> morningSummaryEnabled;
  final Value<String> morningSummaryTime;
  final Value<String> themeMode;
  final Value<DateTime> updatedAt;
  final Value<bool> notificationPromptShown;
  final Value<bool> pendingSync;
  const SettingsEntriesCompanion({
    this.id = const Value.absent(),
    this.dayStart = const Value.absent(),
    this.dayEnd = const Value.absent(),
    this.timezone = const Value.absent(),
    this.defaultReminderMin = const Value.absent(),
    this.morningSummaryEnabled = const Value.absent(),
    this.morningSummaryTime = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.notificationPromptShown = const Value.absent(),
    this.pendingSync = const Value.absent(),
  });
  SettingsEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String dayStart,
    required String dayEnd,
    required String timezone,
    required int defaultReminderMin,
    required bool morningSummaryEnabled,
    required String morningSummaryTime,
    required String themeMode,
    required DateTime updatedAt,
    this.notificationPromptShown = const Value.absent(),
    this.pendingSync = const Value.absent(),
  }) : dayStart = Value(dayStart),
       dayEnd = Value(dayEnd),
       timezone = Value(timezone),
       defaultReminderMin = Value(defaultReminderMin),
       morningSummaryEnabled = Value(morningSummaryEnabled),
       morningSummaryTime = Value(morningSummaryTime),
       themeMode = Value(themeMode),
       updatedAt = Value(updatedAt);
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<String>? dayStart,
    Expression<String>? dayEnd,
    Expression<String>? timezone,
    Expression<int>? defaultReminderMin,
    Expression<bool>? morningSummaryEnabled,
    Expression<String>? morningSummaryTime,
    Expression<String>? themeMode,
    Expression<DateTime>? updatedAt,
    Expression<bool>? notificationPromptShown,
    Expression<bool>? pendingSync,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayStart != null) 'day_start': dayStart,
      if (dayEnd != null) 'day_end': dayEnd,
      if (timezone != null) 'timezone': timezone,
      if (defaultReminderMin != null)
        'default_reminder_min': defaultReminderMin,
      if (morningSummaryEnabled != null)
        'morning_summary_enabled': morningSummaryEnabled,
      if (morningSummaryTime != null)
        'morning_summary_time': morningSummaryTime,
      if (themeMode != null) 'theme_mode': themeMode,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (notificationPromptShown != null)
        'notification_prompt_shown': notificationPromptShown,
      if (pendingSync != null) 'pending_sync': pendingSync,
    });
  }

  SettingsEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? dayStart,
    Value<String>? dayEnd,
    Value<String>? timezone,
    Value<int>? defaultReminderMin,
    Value<bool>? morningSummaryEnabled,
    Value<String>? morningSummaryTime,
    Value<String>? themeMode,
    Value<DateTime>? updatedAt,
    Value<bool>? notificationPromptShown,
    Value<bool>? pendingSync,
  }) {
    return SettingsEntriesCompanion(
      id: id ?? this.id,
      dayStart: dayStart ?? this.dayStart,
      dayEnd: dayEnd ?? this.dayEnd,
      timezone: timezone ?? this.timezone,
      defaultReminderMin: defaultReminderMin ?? this.defaultReminderMin,
      morningSummaryEnabled:
          morningSummaryEnabled ?? this.morningSummaryEnabled,
      morningSummaryTime: morningSummaryTime ?? this.morningSummaryTime,
      themeMode: themeMode ?? this.themeMode,
      updatedAt: updatedAt ?? this.updatedAt,
      notificationPromptShown:
          notificationPromptShown ?? this.notificationPromptShown,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayStart.present) {
      map['day_start'] = Variable<String>(dayStart.value);
    }
    if (dayEnd.present) {
      map['day_end'] = Variable<String>(dayEnd.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (defaultReminderMin.present) {
      map['default_reminder_min'] = Variable<int>(defaultReminderMin.value);
    }
    if (morningSummaryEnabled.present) {
      map['morning_summary_enabled'] = Variable<bool>(
        morningSummaryEnabled.value,
      );
    }
    if (morningSummaryTime.present) {
      map['morning_summary_time'] = Variable<String>(morningSummaryTime.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (notificationPromptShown.present) {
      map['notification_prompt_shown'] = Variable<bool>(
        notificationPromptShown.value,
      );
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntriesCompanion(')
          ..write('id: $id, ')
          ..write('dayStart: $dayStart, ')
          ..write('dayEnd: $dayEnd, ')
          ..write('timezone: $timezone, ')
          ..write('defaultReminderMin: $defaultReminderMin, ')
          ..write('morningSummaryEnabled: $morningSummaryEnabled, ')
          ..write('morningSummaryTime: $morningSummaryTime, ')
          ..write('themeMode: $themeMode, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('notificationPromptShown: $notificationPromptShown, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorsTable extends SyncCursors
    with TableInfo<$SyncCursorsTable, SyncCursorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _tasksSyncedAtMeta = const VerificationMeta(
    'tasksSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> tasksSyncedAt =
      GeneratedColumn<DateTime>(
        'tasks_synced_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [id, tasksSyncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tasks_synced_at')) {
      context.handle(
        _tasksSyncedAtMeta,
        tasksSyncedAt.isAcceptableOrUnknown(
          data['tasks_synced_at']!,
          _tasksSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncCursorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursorRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tasksSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}tasks_synced_at'],
      ),
    );
  }

  @override
  $SyncCursorsTable createAlias(String alias) {
    return $SyncCursorsTable(attachedDatabase, alias);
  }
}

class SyncCursorRow extends DataClass implements Insertable<SyncCursorRow> {
  final int id;
  final DateTime? tasksSyncedAt;
  const SyncCursorRow({required this.id, this.tasksSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || tasksSyncedAt != null) {
      map['tasks_synced_at'] = Variable<DateTime>(tasksSyncedAt);
    }
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(
      id: Value(id),
      tasksSyncedAt: tasksSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(tasksSyncedAt),
    );
  }

  factory SyncCursorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursorRow(
      id: serializer.fromJson<int>(json['id']),
      tasksSyncedAt: serializer.fromJson<DateTime?>(json['tasksSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tasksSyncedAt': serializer.toJson<DateTime?>(tasksSyncedAt),
    };
  }

  SyncCursorRow copyWith({
    int? id,
    Value<DateTime?> tasksSyncedAt = const Value.absent(),
  }) => SyncCursorRow(
    id: id ?? this.id,
    tasksSyncedAt: tasksSyncedAt.present
        ? tasksSyncedAt.value
        : this.tasksSyncedAt,
  );
  SyncCursorRow copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursorRow(
      id: data.id.present ? data.id.value : this.id,
      tasksSyncedAt: data.tasksSyncedAt.present
          ? data.tasksSyncedAt.value
          : this.tasksSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorRow(')
          ..write('id: $id, ')
          ..write('tasksSyncedAt: $tasksSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tasksSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursorRow &&
          other.id == this.id &&
          other.tasksSyncedAt == this.tasksSyncedAt);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursorRow> {
  final Value<int> id;
  final Value<DateTime?> tasksSyncedAt;
  const SyncCursorsCompanion({
    this.id = const Value.absent(),
    this.tasksSyncedAt = const Value.absent(),
  });
  SyncCursorsCompanion.insert({
    this.id = const Value.absent(),
    this.tasksSyncedAt = const Value.absent(),
  });
  static Insertable<SyncCursorRow> custom({
    Expression<int>? id,
    Expression<DateTime>? tasksSyncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tasksSyncedAt != null) 'tasks_synced_at': tasksSyncedAt,
    });
  }

  SyncCursorsCompanion copyWith({
    Value<int>? id,
    Value<DateTime?>? tasksSyncedAt,
  }) {
    return SyncCursorsCompanion(
      id: id ?? this.id,
      tasksSyncedAt: tasksSyncedAt ?? this.tasksSyncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tasksSyncedAt.present) {
      map['tasks_synced_at'] = Variable<DateTime>(tasksSyncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('id: $id, ')
          ..write('tasksSyncedAt: $tasksSyncedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $SettingsEntriesTable settingsEntries = $SettingsEntriesTable(
    this,
  );
  late final $SyncCursorsTable syncCursors = $SyncCursorsTable(this);
  late final Index tasksDateIdx = Index(
    'tasks_date_idx',
    'CREATE INDEX tasks_date_idx ON tasks (date)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tasks,
    settingsEntries,
    syncCursors,
    tasksDateIdx,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  required String title,
  required String date,
  required String startTime,
  required String endTime,
  Value<String> categoryId,
  Value<String?> notes,
  Value<int?> reminderBeforeMin,
  Value<String> status,
  Value<bool> shifted,
  Value<String?> originalStartTime,
  Value<String> source,
  Value<String?> importBatchId,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> pendingSync,
  Value<int> rowid,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> date,
  Value<String> startTime,
  Value<String> endTime,
  Value<String> categoryId,
  Value<String?> notes,
  Value<int?> reminderBeforeMin,
  Value<String> status,
  Value<bool> shifted,
  Value<String?> originalStartTime,
  Value<String> source,
  Value<String?> importBatchId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> pendingSync,
  Value<int> rowid,
});

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderBeforeMin => $composableBuilder(
    column: $table.reminderBeforeMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get shifted => $composableBuilder(
    column: $table.shifted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalStartTime => $composableBuilder(
    column: $table.originalStartTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get importBatchId => $composableBuilder(
    column: $table.importBatchId,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderBeforeMin => $composableBuilder(
    column: $table.reminderBeforeMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get shifted => $composableBuilder(
    column: $table.shifted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalStartTime => $composableBuilder(
    column: $table.originalStartTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get importBatchId => $composableBuilder(
    column: $table.importBatchId,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get reminderBeforeMin => $composableBuilder(
    column: $table.reminderBeforeMin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get shifted =>
      $composableBuilder(column: $table.shifted, builder: (column) => column);

  GeneratedColumn<String> get originalStartTime => $composableBuilder(
    column: $table.originalStartTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get importBatchId => $composableBuilder(
    column: $table.importBatchId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => column,
  );
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          TaskRow,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (TaskRow, BaseReferences<_$AppDatabase, $TasksTable, TaskRow>),
          TaskRow,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> startTime = const Value.absent(),
                Value<String> endTime = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> reminderBeforeMin = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> shifted = const Value.absent(),
                Value<String?> originalStartTime = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> importBatchId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendingSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                date: date,
                startTime: startTime,
                endTime: endTime,
                categoryId: categoryId,
                notes: notes,
                reminderBeforeMin: reminderBeforeMin,
                status: status,
                shifted: shifted,
                originalStartTime: originalStartTime,
                source: source,
                importBatchId: importBatchId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendingSync: pendingSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String date,
                required String startTime,
                required String endTime,
                Value<String> categoryId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> reminderBeforeMin = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> shifted = const Value.absent(),
                Value<String?> originalStartTime = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> importBatchId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> pendingSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                date: date,
                startTime: startTime,
                endTime: endTime,
                categoryId: categoryId,
                notes: notes,
                reminderBeforeMin: reminderBeforeMin,
                status: status,
                shifted: shifted,
                originalStartTime: originalStartTime,
                source: source,
                importBatchId: importBatchId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pendingSync: pendingSync,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTable, TaskRow>(table),
                  BaseReferences<_$AppDatabase, $TasksTable, TaskRow>(
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

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      TaskRow,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (TaskRow, BaseReferences<_$AppDatabase, $TasksTable, TaskRow>),
      TaskRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsEntriesTableCreateCompanionBuilder =
    SettingsEntriesCompanion Function({
      Value<int> id,
      required String dayStart,
      required String dayEnd,
      required String timezone,
      required int defaultReminderMin,
      required bool morningSummaryEnabled,
      required String morningSummaryTime,
      required String themeMode,
      required DateTime updatedAt,
      Value<bool> notificationPromptShown,
      Value<bool> pendingSync,
    });
typedef $$SettingsEntriesTableUpdateCompanionBuilder =
    SettingsEntriesCompanion Function({
      Value<int> id,
      Value<String> dayStart,
      Value<String> dayEnd,
      Value<String> timezone,
      Value<int> defaultReminderMin,
      Value<bool> morningSummaryEnabled,
      Value<String> morningSummaryTime,
      Value<String> themeMode,
      Value<DateTime> updatedAt,
      Value<bool> notificationPromptShown,
      Value<bool> pendingSync,
    });

class $$SettingsEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableFilterComposer({
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

  ColumnFilters<String> get dayStart => $composableBuilder(
    column: $table.dayStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayEnd => $composableBuilder(
    column: $table.dayEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultReminderMin => $composableBuilder(
    column: $table.defaultReminderMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get morningSummaryEnabled => $composableBuilder(
    column: $table.morningSummaryEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get morningSummaryTime => $composableBuilder(
    column: $table.morningSummaryTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationPromptShown => $composableBuilder(
    column: $table.notificationPromptShown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get dayStart => $composableBuilder(
    column: $table.dayStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayEnd => $composableBuilder(
    column: $table.dayEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultReminderMin => $composableBuilder(
    column: $table.defaultReminderMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get morningSummaryEnabled => $composableBuilder(
    column: $table.morningSummaryEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get morningSummaryTime => $composableBuilder(
    column: $table.morningSummaryTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationPromptShown => $composableBuilder(
    column: $table.notificationPromptShown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dayStart =>
      $composableBuilder(column: $table.dayStart, builder: (column) => column);

  GeneratedColumn<String> get dayEnd =>
      $composableBuilder(column: $table.dayEnd, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<int> get defaultReminderMin => $composableBuilder(
    column: $table.defaultReminderMin,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get morningSummaryEnabled => $composableBuilder(
    column: $table.morningSummaryEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get morningSummaryTime => $composableBuilder(
    column: $table.morningSummaryTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get notificationPromptShown => $composableBuilder(
    column: $table.notificationPromptShown,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => column,
  );
}

class $$SettingsEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsEntriesTable,
          SettingsRow,
          $$SettingsEntriesTableFilterComposer,
          $$SettingsEntriesTableOrderingComposer,
          $$SettingsEntriesTableAnnotationComposer,
          $$SettingsEntriesTableCreateCompanionBuilder,
          $$SettingsEntriesTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsRow>,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$SettingsEntriesTableTableManager(
    _$AppDatabase db,
    $SettingsEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> dayStart = const Value.absent(),
                Value<String> dayEnd = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<int> defaultReminderMin = const Value.absent(),
                Value<bool> morningSummaryEnabled = const Value.absent(),
                Value<String> morningSummaryTime = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> notificationPromptShown = const Value.absent(),
                Value<bool> pendingSync = const Value.absent(),
              }) => SettingsEntriesCompanion(
                id: id,
                dayStart: dayStart,
                dayEnd: dayEnd,
                timezone: timezone,
                defaultReminderMin: defaultReminderMin,
                morningSummaryEnabled: morningSummaryEnabled,
                morningSummaryTime: morningSummaryTime,
                themeMode: themeMode,
                updatedAt: updatedAt,
                notificationPromptShown: notificationPromptShown,
                pendingSync: pendingSync,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String dayStart,
                required String dayEnd,
                required String timezone,
                required int defaultReminderMin,
                required bool morningSummaryEnabled,
                required String morningSummaryTime,
                required String themeMode,
                required DateTime updatedAt,
                Value<bool> notificationPromptShown = const Value.absent(),
                Value<bool> pendingSync = const Value.absent(),
              }) => SettingsEntriesCompanion.insert(
                id: id,
                dayStart: dayStart,
                dayEnd: dayEnd,
                timezone: timezone,
                defaultReminderMin: defaultReminderMin,
                morningSummaryEnabled: morningSummaryEnabled,
                morningSummaryTime: morningSummaryTime,
                themeMode: themeMode,
                updatedAt: updatedAt,
                notificationPromptShown: notificationPromptShown,
                pendingSync: pendingSync,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsEntriesTable, SettingsRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SettingsEntriesTable,
                    SettingsRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsEntriesTable,
      SettingsRow,
      $$SettingsEntriesTableFilterComposer,
      $$SettingsEntriesTableOrderingComposer,
      $$SettingsEntriesTableAnnotationComposer,
      $$SettingsEntriesTableCreateCompanionBuilder,
      $$SettingsEntriesTableUpdateCompanionBuilder,
      (
        SettingsRow,
        BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsRow>,
      ),
      SettingsRow,
      PrefetchHooks Function()
    >;
typedef $$SyncCursorsTableCreateCompanionBuilder =
    SyncCursorsCompanion Function({
      Value<int> id,
      Value<DateTime?> tasksSyncedAt,
    });
typedef $$SyncCursorsTableUpdateCompanionBuilder =
    SyncCursorsCompanion Function({
      Value<int> id,
      Value<DateTime?> tasksSyncedAt,
    });

class $$SyncCursorsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableFilterComposer({
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

  ColumnFilters<DateTime> get tasksSyncedAt => $composableBuilder(
    column: $table.tasksSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCursorsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get tasksSyncedAt => $composableBuilder(
    column: $table.tasksSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCursorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get tasksSyncedAt => $composableBuilder(
    column: $table.tasksSyncedAt,
    builder: (column) => column,
  );
}

class $$SyncCursorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCursorsTable,
          SyncCursorRow,
          $$SyncCursorsTableFilterComposer,
          $$SyncCursorsTableOrderingComposer,
          $$SyncCursorsTableAnnotationComposer,
          $$SyncCursorsTableCreateCompanionBuilder,
          $$SyncCursorsTableUpdateCompanionBuilder,
          (
            SyncCursorRow,
            BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursorRow>,
          ),
          SyncCursorRow,
          PrefetchHooks Function()
        > {
  $$SyncCursorsTableTableManager(_$AppDatabase db, $SyncCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime?> tasksSyncedAt = const Value.absent(),
          }) => SyncCursorsCompanion(id: id, tasksSyncedAt: tasksSyncedAt),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime?> tasksSyncedAt = const Value.absent(),
              }) => SyncCursorsCompanion.insert(
                id: id,
                tasksSyncedAt: tasksSyncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncCursorsTable, SyncCursorRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncCursorsTable,
                    SyncCursorRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCursorsTable,
      SyncCursorRow,
      $$SyncCursorsTableFilterComposer,
      $$SyncCursorsTableOrderingComposer,
      $$SyncCursorsTableAnnotationComposer,
      $$SyncCursorsTableCreateCompanionBuilder,
      $$SyncCursorsTableUpdateCompanionBuilder,
      (
        SyncCursorRow,
        BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursorRow>,
      ),
      SyncCursorRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$SettingsEntriesTableTableManager get settingsEntries =>
      $$SettingsEntriesTableTableManager(_db, _db.settingsEntries);
  $$SyncCursorsTableTableManager get syncCursors =>
      $$SyncCursorsTableTableManager(_db, _db.syncCursors);
}
