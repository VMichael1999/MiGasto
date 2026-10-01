// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MovimientosTable extends Movimientos
    with TableInfo<$MovimientosTable, MovimientoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovimientosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantMeta = const VerificationMeta(
    'merchant',
  );
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNameMeta = const VerificationMeta(
    'sourceName',
  );
  @override
  late final GeneratedColumn<String> sourceName = GeneratedColumn<String>(
    'source_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _tipoNameMeta = const VerificationMeta(
    'tipoName',
  );
  @override
  late final GeneratedColumn<String> tipoName = GeneratedColumn<String>(
    'tipo_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('gasto'),
  );
  static const VerificationMeta _estadoNameMeta = const VerificationMeta(
    'estadoName',
  );
  @override
  late final GeneratedColumn<String> estadoName = GeneratedColumn<String>(
    'estado_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pendiente'),
  );
  static const VerificationMeta _canalNameMeta = const VerificationMeta(
    'canalName',
  );
  @override
  late final GeneratedColumn<String> canalName = GeneratedColumn<String>(
    'canal_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _tarjetaMeta = const VerificationMeta(
    'tarjeta',
  );
  @override
  late final GeneratedColumn<String> tarjeta = GeneratedColumn<String>(
    'tarjeta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudMeta = const VerificationMeta(
    'latitud',
  );
  @override
  late final GeneratedColumn<double> latitud = GeneratedColumn<double>(
    'latitud',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudMeta = const VerificationMeta(
    'longitud',
  );
  @override
  late final GeneratedColumn<double> longitud = GeneratedColumn<double>(
    'longitud',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _precisionMeta = const VerificationMeta(
    'precision',
  );
  @override
  late final GeneratedColumn<double> precision = GeneratedColumn<double>(
    'precision',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lugarMeta = const VerificationMeta('lugar');
  @override
  late final GeneratedColumn<String> lugar = GeneratedColumn<String>(
    'lugar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textoOriginalMeta = const VerificationMeta(
    'textoOriginal',
  );
  @override
  late final GeneratedColumn<String> textoOriginal = GeneratedColumn<String>(
    'texto_original',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    amount,
    merchant,
    categoryName,
    sourceName,
    date,
    notes,
    tipoName,
    estadoName,
    canalName,
    tarjeta,
    latitud,
    longitud,
    precision,
    lugar,
    textoOriginal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movimientos';
  @override
  VerificationContext validateIntegrity(
    Insertable<MovimientoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('merchant')) {
      context.handle(
        _merchantMeta,
        merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta),
      );
    } else if (isInserting) {
      context.missing(_merchantMeta);
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryNameMeta);
    }
    if (data.containsKey('source_name')) {
      context.handle(
        _sourceNameMeta,
        sourceName.isAcceptableOrUnknown(data['source_name']!, _sourceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceNameMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('tipo_name')) {
      context.handle(
        _tipoNameMeta,
        tipoName.isAcceptableOrUnknown(data['tipo_name']!, _tipoNameMeta),
      );
    }
    if (data.containsKey('estado_name')) {
      context.handle(
        _estadoNameMeta,
        estadoName.isAcceptableOrUnknown(data['estado_name']!, _estadoNameMeta),
      );
    }
    if (data.containsKey('canal_name')) {
      context.handle(
        _canalNameMeta,
        canalName.isAcceptableOrUnknown(data['canal_name']!, _canalNameMeta),
      );
    }
    if (data.containsKey('tarjeta')) {
      context.handle(
        _tarjetaMeta,
        tarjeta.isAcceptableOrUnknown(data['tarjeta']!, _tarjetaMeta),
      );
    }
    if (data.containsKey('latitud')) {
      context.handle(
        _latitudMeta,
        latitud.isAcceptableOrUnknown(data['latitud']!, _latitudMeta),
      );
    }
    if (data.containsKey('longitud')) {
      context.handle(
        _longitudMeta,
        longitud.isAcceptableOrUnknown(data['longitud']!, _longitudMeta),
      );
    }
    if (data.containsKey('precision')) {
      context.handle(
        _precisionMeta,
        precision.isAcceptableOrUnknown(data['precision']!, _precisionMeta),
      );
    }
    if (data.containsKey('lugar')) {
      context.handle(
        _lugarMeta,
        lugar.isAcceptableOrUnknown(data['lugar']!, _lugarMeta),
      );
    }
    if (data.containsKey('texto_original')) {
      context.handle(
        _textoOriginalMeta,
        textoOriginal.isAcceptableOrUnknown(
          data['texto_original']!,
          _textoOriginalMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  MovimientoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MovimientoRow(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      merchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant'],
      )!,
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      )!,
      sourceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_name'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      tipoName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_name'],
      )!,
      estadoName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado_name'],
      )!,
      canalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canal_name'],
      )!,
      tarjeta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tarjeta'],
      ),
      latitud: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitud'],
      ),
      longitud: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitud'],
      ),
      precision: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}precision'],
      ),
      lugar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lugar'],
      ),
      textoOriginal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}texto_original'],
      )!,
    );
  }

  @override
  $MovimientosTable createAlias(String alias) {
    return $MovimientosTable(attachedDatabase, alias);
  }
}

class MovimientoRow extends DataClass implements Insertable<MovimientoRow> {
  final String uuid;
  final double amount;
  final String merchant;
  final String categoryName;
  final String sourceName;
  final DateTime date;
  final String notes;
  final String tipoName;
  final String estadoName;
  final String canalName;
  final String? tarjeta;
  final double? latitud;
  final double? longitud;
  final double? precision;
  final String? lugar;
  final String textoOriginal;
  const MovimientoRow({
    required this.uuid,
    required this.amount,
    required this.merchant,
    required this.categoryName,
    required this.sourceName,
    required this.date,
    required this.notes,
    required this.tipoName,
    required this.estadoName,
    required this.canalName,
    this.tarjeta,
    this.latitud,
    this.longitud,
    this.precision,
    this.lugar,
    required this.textoOriginal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['amount'] = Variable<double>(amount);
    map['merchant'] = Variable<String>(merchant);
    map['category_name'] = Variable<String>(categoryName);
    map['source_name'] = Variable<String>(sourceName);
    map['date'] = Variable<DateTime>(date);
    map['notes'] = Variable<String>(notes);
    map['tipo_name'] = Variable<String>(tipoName);
    map['estado_name'] = Variable<String>(estadoName);
    map['canal_name'] = Variable<String>(canalName);
    if (!nullToAbsent || tarjeta != null) {
      map['tarjeta'] = Variable<String>(tarjeta);
    }
    if (!nullToAbsent || latitud != null) {
      map['latitud'] = Variable<double>(latitud);
    }
    if (!nullToAbsent || longitud != null) {
      map['longitud'] = Variable<double>(longitud);
    }
    if (!nullToAbsent || precision != null) {
      map['precision'] = Variable<double>(precision);
    }
    if (!nullToAbsent || lugar != null) {
      map['lugar'] = Variable<String>(lugar);
    }
    map['texto_original'] = Variable<String>(textoOriginal);
    return map;
  }

  MovimientosCompanion toCompanion(bool nullToAbsent) {
    return MovimientosCompanion(
      uuid: Value(uuid),
      amount: Value(amount),
      merchant: Value(merchant),
      categoryName: Value(categoryName),
      sourceName: Value(sourceName),
      date: Value(date),
      notes: Value(notes),
      tipoName: Value(tipoName),
      estadoName: Value(estadoName),
      canalName: Value(canalName),
      tarjeta: tarjeta == null && nullToAbsent
          ? const Value.absent()
          : Value(tarjeta),
      latitud: latitud == null && nullToAbsent
          ? const Value.absent()
          : Value(latitud),
      longitud: longitud == null && nullToAbsent
          ? const Value.absent()
          : Value(longitud),
      precision: precision == null && nullToAbsent
          ? const Value.absent()
          : Value(precision),
      lugar: lugar == null && nullToAbsent
          ? const Value.absent()
          : Value(lugar),
      textoOriginal: Value(textoOriginal),
    );
  }

  factory MovimientoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MovimientoRow(
      uuid: serializer.fromJson<String>(json['uuid']),
      amount: serializer.fromJson<double>(json['amount']),
      merchant: serializer.fromJson<String>(json['merchant']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      sourceName: serializer.fromJson<String>(json['sourceName']),
      date: serializer.fromJson<DateTime>(json['date']),
      notes: serializer.fromJson<String>(json['notes']),
      tipoName: serializer.fromJson<String>(json['tipoName']),
      estadoName: serializer.fromJson<String>(json['estadoName']),
      canalName: serializer.fromJson<String>(json['canalName']),
      tarjeta: serializer.fromJson<String?>(json['tarjeta']),
      latitud: serializer.fromJson<double?>(json['latitud']),
      longitud: serializer.fromJson<double?>(json['longitud']),
      precision: serializer.fromJson<double?>(json['precision']),
      lugar: serializer.fromJson<String?>(json['lugar']),
      textoOriginal: serializer.fromJson<String>(json['textoOriginal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'amount': serializer.toJson<double>(amount),
      'merchant': serializer.toJson<String>(merchant),
      'categoryName': serializer.toJson<String>(categoryName),
      'sourceName': serializer.toJson<String>(sourceName),
      'date': serializer.toJson<DateTime>(date),
      'notes': serializer.toJson<String>(notes),
      'tipoName': serializer.toJson<String>(tipoName),
      'estadoName': serializer.toJson<String>(estadoName),
      'canalName': serializer.toJson<String>(canalName),
      'tarjeta': serializer.toJson<String?>(tarjeta),
      'latitud': serializer.toJson<double?>(latitud),
      'longitud': serializer.toJson<double?>(longitud),
      'precision': serializer.toJson<double?>(precision),
      'lugar': serializer.toJson<String?>(lugar),
      'textoOriginal': serializer.toJson<String>(textoOriginal),
    };
  }

  MovimientoRow copyWith({
    String? uuid,
    double? amount,
    String? merchant,
    String? categoryName,
    String? sourceName,
    DateTime? date,
    String? notes,
    String? tipoName,
    String? estadoName,
    String? canalName,
    Value<String?> tarjeta = const Value.absent(),
    Value<double?> latitud = const Value.absent(),
    Value<double?> longitud = const Value.absent(),
    Value<double?> precision = const Value.absent(),
    Value<String?> lugar = const Value.absent(),
    String? textoOriginal,
  }) => MovimientoRow(
    uuid: uuid ?? this.uuid,
    amount: amount ?? this.amount,
    merchant: merchant ?? this.merchant,
    categoryName: categoryName ?? this.categoryName,
    sourceName: sourceName ?? this.sourceName,
    date: date ?? this.date,
    notes: notes ?? this.notes,
    tipoName: tipoName ?? this.tipoName,
    estadoName: estadoName ?? this.estadoName,
    canalName: canalName ?? this.canalName,
    tarjeta: tarjeta.present ? tarjeta.value : this.tarjeta,
    latitud: latitud.present ? latitud.value : this.latitud,
    longitud: longitud.present ? longitud.value : this.longitud,
    precision: precision.present ? precision.value : this.precision,
    lugar: lugar.present ? lugar.value : this.lugar,
    textoOriginal: textoOriginal ?? this.textoOriginal,
  );
  MovimientoRow copyWithCompanion(MovimientosCompanion data) {
    return MovimientoRow(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      amount: data.amount.present ? data.amount.value : this.amount,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      sourceName: data.sourceName.present
          ? data.sourceName.value
          : this.sourceName,
      date: data.date.present ? data.date.value : this.date,
      notes: data.notes.present ? data.notes.value : this.notes,
      tipoName: data.tipoName.present ? data.tipoName.value : this.tipoName,
      estadoName: data.estadoName.present
          ? data.estadoName.value
          : this.estadoName,
      canalName: data.canalName.present ? data.canalName.value : this.canalName,
      tarjeta: data.tarjeta.present ? data.tarjeta.value : this.tarjeta,
      latitud: data.latitud.present ? data.latitud.value : this.latitud,
      longitud: data.longitud.present ? data.longitud.value : this.longitud,
      precision: data.precision.present ? data.precision.value : this.precision,
      lugar: data.lugar.present ? data.lugar.value : this.lugar,
      textoOriginal: data.textoOriginal.present
          ? data.textoOriginal.value
          : this.textoOriginal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MovimientoRow(')
          ..write('uuid: $uuid, ')
          ..write('amount: $amount, ')
          ..write('merchant: $merchant, ')
          ..write('categoryName: $categoryName, ')
          ..write('sourceName: $sourceName, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('tipoName: $tipoName, ')
          ..write('estadoName: $estadoName, ')
          ..write('canalName: $canalName, ')
          ..write('tarjeta: $tarjeta, ')
          ..write('latitud: $latitud, ')
          ..write('longitud: $longitud, ')
          ..write('precision: $precision, ')
          ..write('lugar: $lugar, ')
          ..write('textoOriginal: $textoOriginal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    amount,
    merchant,
    categoryName,
    sourceName,
    date,
    notes,
    tipoName,
    estadoName,
    canalName,
    tarjeta,
    latitud,
    longitud,
    precision,
    lugar,
    textoOriginal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MovimientoRow &&
          other.uuid == this.uuid &&
          other.amount == this.amount &&
          other.merchant == this.merchant &&
          other.categoryName == this.categoryName &&
          other.sourceName == this.sourceName &&
          other.date == this.date &&
          other.notes == this.notes &&
          other.tipoName == this.tipoName &&
          other.estadoName == this.estadoName &&
          other.canalName == this.canalName &&
          other.tarjeta == this.tarjeta &&
          other.latitud == this.latitud &&
          other.longitud == this.longitud &&
          other.precision == this.precision &&
          other.lugar == this.lugar &&
          other.textoOriginal == this.textoOriginal);
}

class MovimientosCompanion extends UpdateCompanion<MovimientoRow> {
  final Value<String> uuid;
  final Value<double> amount;
  final Value<String> merchant;
  final Value<String> categoryName;
  final Value<String> sourceName;
  final Value<DateTime> date;
  final Value<String> notes;
  final Value<String> tipoName;
  final Value<String> estadoName;
  final Value<String> canalName;
  final Value<String?> tarjeta;
  final Value<double?> latitud;
  final Value<double?> longitud;
  final Value<double?> precision;
  final Value<String?> lugar;
  final Value<String> textoOriginal;
  final Value<int> rowid;
  const MovimientosCompanion({
    this.uuid = const Value.absent(),
    this.amount = const Value.absent(),
    this.merchant = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.sourceName = const Value.absent(),
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
    this.tipoName = const Value.absent(),
    this.estadoName = const Value.absent(),
    this.canalName = const Value.absent(),
    this.tarjeta = const Value.absent(),
    this.latitud = const Value.absent(),
    this.longitud = const Value.absent(),
    this.precision = const Value.absent(),
    this.lugar = const Value.absent(),
    this.textoOriginal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MovimientosCompanion.insert({
    required String uuid,
    required double amount,
    required String merchant,
    required String categoryName,
    required String sourceName,
    required DateTime date,
    this.notes = const Value.absent(),
    this.tipoName = const Value.absent(),
    this.estadoName = const Value.absent(),
    this.canalName = const Value.absent(),
    this.tarjeta = const Value.absent(),
    this.latitud = const Value.absent(),
    this.longitud = const Value.absent(),
    this.precision = const Value.absent(),
    this.lugar = const Value.absent(),
    this.textoOriginal = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       amount = Value(amount),
       merchant = Value(merchant),
       categoryName = Value(categoryName),
       sourceName = Value(sourceName),
       date = Value(date);
  static Insertable<MovimientoRow> custom({
    Expression<String>? uuid,
    Expression<double>? amount,
    Expression<String>? merchant,
    Expression<String>? categoryName,
    Expression<String>? sourceName,
    Expression<DateTime>? date,
    Expression<String>? notes,
    Expression<String>? tipoName,
    Expression<String>? estadoName,
    Expression<String>? canalName,
    Expression<String>? tarjeta,
    Expression<double>? latitud,
    Expression<double>? longitud,
    Expression<double>? precision,
    Expression<String>? lugar,
    Expression<String>? textoOriginal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (amount != null) 'amount': amount,
      if (merchant != null) 'merchant': merchant,
      if (categoryName != null) 'category_name': categoryName,
      if (sourceName != null) 'source_name': sourceName,
      if (date != null) 'date': date,
      if (notes != null) 'notes': notes,
      if (tipoName != null) 'tipo_name': tipoName,
      if (estadoName != null) 'estado_name': estadoName,
      if (canalName != null) 'canal_name': canalName,
      if (tarjeta != null) 'tarjeta': tarjeta,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
      if (precision != null) 'precision': precision,
      if (lugar != null) 'lugar': lugar,
      if (textoOriginal != null) 'texto_original': textoOriginal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MovimientosCompanion copyWith({
    Value<String>? uuid,
    Value<double>? amount,
    Value<String>? merchant,
    Value<String>? categoryName,
    Value<String>? sourceName,
    Value<DateTime>? date,
    Value<String>? notes,
    Value<String>? tipoName,
    Value<String>? estadoName,
    Value<String>? canalName,
    Value<String?>? tarjeta,
    Value<double?>? latitud,
    Value<double?>? longitud,
    Value<double?>? precision,
    Value<String?>? lugar,
    Value<String>? textoOriginal,
    Value<int>? rowid,
  }) {
    return MovimientosCompanion(
      uuid: uuid ?? this.uuid,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      categoryName: categoryName ?? this.categoryName,
      sourceName: sourceName ?? this.sourceName,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      tipoName: tipoName ?? this.tipoName,
      estadoName: estadoName ?? this.estadoName,
      canalName: canalName ?? this.canalName,
      tarjeta: tarjeta ?? this.tarjeta,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      precision: precision ?? this.precision,
      lugar: lugar ?? this.lugar,
      textoOriginal: textoOriginal ?? this.textoOriginal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (sourceName.present) {
      map['source_name'] = Variable<String>(sourceName.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (tipoName.present) {
      map['tipo_name'] = Variable<String>(tipoName.value);
    }
    if (estadoName.present) {
      map['estado_name'] = Variable<String>(estadoName.value);
    }
    if (canalName.present) {
      map['canal_name'] = Variable<String>(canalName.value);
    }
    if (tarjeta.present) {
      map['tarjeta'] = Variable<String>(tarjeta.value);
    }
    if (latitud.present) {
      map['latitud'] = Variable<double>(latitud.value);
    }
    if (longitud.present) {
      map['longitud'] = Variable<double>(longitud.value);
    }
    if (precision.present) {
      map['precision'] = Variable<double>(precision.value);
    }
    if (lugar.present) {
      map['lugar'] = Variable<String>(lugar.value);
    }
    if (textoOriginal.present) {
      map['texto_original'] = Variable<String>(textoOriginal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovimientosCompanion(')
          ..write('uuid: $uuid, ')
          ..write('amount: $amount, ')
          ..write('merchant: $merchant, ')
          ..write('categoryName: $categoryName, ')
          ..write('sourceName: $sourceName, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('tipoName: $tipoName, ')
          ..write('estadoName: $estadoName, ')
          ..write('canalName: $canalName, ')
          ..write('tarjeta: $tarjeta, ')
          ..write('latitud: $latitud, ')
          ..write('longitud: $longitud, ')
          ..write('precision: $precision, ')
          ..write('lugar: $lugar, ')
          ..write('textoOriginal: $textoOriginal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MovimientosTable movimientos = $MovimientosTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [movimientos];
}

typedef $$MovimientosTableCreateCompanionBuilder =
    MovimientosCompanion Function({
      required String uuid,
      required double amount,
      required String merchant,
      required String categoryName,
      required String sourceName,
      required DateTime date,
      Value<String> notes,
      Value<String> tipoName,
      Value<String> estadoName,
      Value<String> canalName,
      Value<String?> tarjeta,
      Value<double?> latitud,
      Value<double?> longitud,
      Value<double?> precision,
      Value<String?> lugar,
      Value<String> textoOriginal,
      Value<int> rowid,
    });
typedef $$MovimientosTableUpdateCompanionBuilder =
    MovimientosCompanion Function({
      Value<String> uuid,
      Value<double> amount,
      Value<String> merchant,
      Value<String> categoryName,
      Value<String> sourceName,
      Value<DateTime> date,
      Value<String> notes,
      Value<String> tipoName,
      Value<String> estadoName,
      Value<String> canalName,
      Value<String?> tarjeta,
      Value<double?> latitud,
      Value<double?> longitud,
      Value<double?> precision,
      Value<String?> lugar,
      Value<String> textoOriginal,
      Value<int> rowid,
    });

class $$MovimientosTableFilterComposer
    extends Composer<_$AppDatabase, $MovimientosTable> {
  $$MovimientosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipoName => $composableBuilder(
    column: $table.tipoName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estadoName => $composableBuilder(
    column: $table.estadoName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canalName => $composableBuilder(
    column: $table.canalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tarjeta => $composableBuilder(
    column: $table.tarjeta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitud => $composableBuilder(
    column: $table.latitud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitud => $composableBuilder(
    column: $table.longitud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get precision => $composableBuilder(
    column: $table.precision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lugar => $composableBuilder(
    column: $table.lugar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textoOriginal => $composableBuilder(
    column: $table.textoOriginal,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MovimientosTableOrderingComposer
    extends Composer<_$AppDatabase, $MovimientosTable> {
  $$MovimientosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipoName => $composableBuilder(
    column: $table.tipoName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estadoName => $composableBuilder(
    column: $table.estadoName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canalName => $composableBuilder(
    column: $table.canalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tarjeta => $composableBuilder(
    column: $table.tarjeta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitud => $composableBuilder(
    column: $table.latitud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitud => $composableBuilder(
    column: $table.longitud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get precision => $composableBuilder(
    column: $table.precision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lugar => $composableBuilder(
    column: $table.lugar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textoOriginal => $composableBuilder(
    column: $table.textoOriginal,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MovimientosTableAnnotationComposer
    extends Composer<_$AppDatabase, $MovimientosTable> {
  $$MovimientosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get tipoName =>
      $composableBuilder(column: $table.tipoName, builder: (column) => column);

  GeneratedColumn<String> get estadoName => $composableBuilder(
    column: $table.estadoName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get canalName =>
      $composableBuilder(column: $table.canalName, builder: (column) => column);

  GeneratedColumn<String> get tarjeta =>
      $composableBuilder(column: $table.tarjeta, builder: (column) => column);

  GeneratedColumn<double> get latitud =>
      $composableBuilder(column: $table.latitud, builder: (column) => column);

  GeneratedColumn<double> get longitud =>
      $composableBuilder(column: $table.longitud, builder: (column) => column);

  GeneratedColumn<double> get precision =>
      $composableBuilder(column: $table.precision, builder: (column) => column);

  GeneratedColumn<String> get lugar =>
      $composableBuilder(column: $table.lugar, builder: (column) => column);

  GeneratedColumn<String> get textoOriginal => $composableBuilder(
    column: $table.textoOriginal,
    builder: (column) => column,
  );
}

class $$MovimientosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MovimientosTable,
          MovimientoRow,
          $$MovimientosTableFilterComposer,
          $$MovimientosTableOrderingComposer,
          $$MovimientosTableAnnotationComposer,
          $$MovimientosTableCreateCompanionBuilder,
          $$MovimientosTableUpdateCompanionBuilder,
          (
            MovimientoRow,
            BaseReferences<_$AppDatabase, $MovimientosTable, MovimientoRow>,
          ),
          MovimientoRow,
          PrefetchHooks Function()
        > {
  $$MovimientosTableTableManager(_$AppDatabase db, $MovimientosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MovimientosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MovimientosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MovimientosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> merchant = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<String> sourceName = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> tipoName = const Value.absent(),
                Value<String> estadoName = const Value.absent(),
                Value<String> canalName = const Value.absent(),
                Value<String?> tarjeta = const Value.absent(),
                Value<double?> latitud = const Value.absent(),
                Value<double?> longitud = const Value.absent(),
                Value<double?> precision = const Value.absent(),
                Value<String?> lugar = const Value.absent(),
                Value<String> textoOriginal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovimientosCompanion(
                uuid: uuid,
                amount: amount,
                merchant: merchant,
                categoryName: categoryName,
                sourceName: sourceName,
                date: date,
                notes: notes,
                tipoName: tipoName,
                estadoName: estadoName,
                canalName: canalName,
                tarjeta: tarjeta,
                latitud: latitud,
                longitud: longitud,
                precision: precision,
                lugar: lugar,
                textoOriginal: textoOriginal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required double amount,
                required String merchant,
                required String categoryName,
                required String sourceName,
                required DateTime date,
                Value<String> notes = const Value.absent(),
                Value<String> tipoName = const Value.absent(),
                Value<String> estadoName = const Value.absent(),
                Value<String> canalName = const Value.absent(),
                Value<String?> tarjeta = const Value.absent(),
                Value<double?> latitud = const Value.absent(),
                Value<double?> longitud = const Value.absent(),
                Value<double?> precision = const Value.absent(),
                Value<String?> lugar = const Value.absent(),
                Value<String> textoOriginal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovimientosCompanion.insert(
                uuid: uuid,
                amount: amount,
                merchant: merchant,
                categoryName: categoryName,
                sourceName: sourceName,
                date: date,
                notes: notes,
                tipoName: tipoName,
                estadoName: estadoName,
                canalName: canalName,
                tarjeta: tarjeta,
                latitud: latitud,
                longitud: longitud,
                precision: precision,
                lugar: lugar,
                textoOriginal: textoOriginal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MovimientosTable, MovimientoRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MovimientosTable,
                    MovimientoRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MovimientosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MovimientosTable,
      MovimientoRow,
      $$MovimientosTableFilterComposer,
      $$MovimientosTableOrderingComposer,
      $$MovimientosTableAnnotationComposer,
      $$MovimientosTableCreateCompanionBuilder,
      $$MovimientosTableUpdateCompanionBuilder,
      (
        MovimientoRow,
        BaseReferences<_$AppDatabase, $MovimientosTable, MovimientoRow>,
      ),
      MovimientoRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MovimientosTableTableManager get movimientos =>
      $$MovimientosTableTableManager(_db, _db.movimientos);
}
