// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetExpenseModelCollection on Isar {
  IsarCollection<ExpenseModel> get expenseModels => this.collection();
}

const ExpenseModelSchema = CollectionSchema(
  name: r'ExpenseModel',
  id: 8411865314220037745,
  properties: {
    r'amount': PropertySchema(
      id: 0,
      name: r'amount',
      type: IsarType.double,
    ),
    r'canalName': PropertySchema(
      id: 1,
      name: r'canalName',
      type: IsarType.string,
    ),
    r'categoryName': PropertySchema(
      id: 2,
      name: r'categoryName',
      type: IsarType.string,
    ),
    r'date': PropertySchema(
      id: 3,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'estadoName': PropertySchema(
      id: 4,
      name: r'estadoName',
      type: IsarType.string,
    ),
    r'isConfirmed': PropertySchema(
      id: 5,
      name: r'isConfirmed',
      type: IsarType.bool,
    ),
    r'latitud': PropertySchema(
      id: 6,
      name: r'latitud',
      type: IsarType.double,
    ),
    r'longitud': PropertySchema(
      id: 7,
      name: r'longitud',
      type: IsarType.double,
    ),
    r'lugar': PropertySchema(
      id: 8,
      name: r'lugar',
      type: IsarType.string,
    ),
    r'merchant': PropertySchema(
      id: 9,
      name: r'merchant',
      type: IsarType.string,
    ),
    r'notes': PropertySchema(
      id: 10,
      name: r'notes',
      type: IsarType.string,
    ),
    r'precision': PropertySchema(
      id: 11,
      name: r'precision',
      type: IsarType.double,
    ),
    r'sourceName': PropertySchema(
      id: 12,
      name: r'sourceName',
      type: IsarType.string,
    ),
    r'tarjeta': PropertySchema(
      id: 13,
      name: r'tarjeta',
      type: IsarType.string,
    ),
    r'textoOriginal': PropertySchema(
      id: 14,
      name: r'textoOriginal',
      type: IsarType.string,
    ),
    r'tipoName': PropertySchema(
      id: 15,
      name: r'tipoName',
      type: IsarType.string,
    ),
    r'uuid': PropertySchema(
      id: 16,
      name: r'uuid',
      type: IsarType.string,
    )
  },
  estimateSize: _expenseModelEstimateSize,
  serialize: _expenseModelSerialize,
  deserialize: _expenseModelDeserialize,
  deserializeProp: _expenseModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _expenseModelGetId,
  getLinks: _expenseModelGetLinks,
  attach: _expenseModelAttach,
  version: '3.1.0+1',
);

int _expenseModelEstimateSize(
  ExpenseModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.canalName.length * 3;
  bytesCount += 3 + object.categoryName.length * 3;
  bytesCount += 3 + object.estadoName.length * 3;
  {
    final value = object.lugar;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.merchant.length * 3;
  bytesCount += 3 + object.notes.length * 3;
  bytesCount += 3 + object.sourceName.length * 3;
  {
    final value = object.tarjeta;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.textoOriginal.length * 3;
  bytesCount += 3 + object.tipoName.length * 3;
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _expenseModelSerialize(
  ExpenseModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.amount);
  writer.writeString(offsets[1], object.canalName);
  writer.writeString(offsets[2], object.categoryName);
  writer.writeDateTime(offsets[3], object.date);
  writer.writeString(offsets[4], object.estadoName);
  writer.writeBool(offsets[5], object.isConfirmed);
  writer.writeDouble(offsets[6], object.latitud);
  writer.writeDouble(offsets[7], object.longitud);
  writer.writeString(offsets[8], object.lugar);
  writer.writeString(offsets[9], object.merchant);
  writer.writeString(offsets[10], object.notes);
  writer.writeDouble(offsets[11], object.precision);
  writer.writeString(offsets[12], object.sourceName);
  writer.writeString(offsets[13], object.tarjeta);
  writer.writeString(offsets[14], object.textoOriginal);
  writer.writeString(offsets[15], object.tipoName);
  writer.writeString(offsets[16], object.uuid);
}

ExpenseModel _expenseModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ExpenseModel();
  object.amount = reader.readDouble(offsets[0]);
  object.canalName = reader.readString(offsets[1]);
  object.categoryName = reader.readString(offsets[2]);
  object.date = reader.readDateTime(offsets[3]);
  object.estadoName = reader.readString(offsets[4]);
  object.id = id;
  object.isConfirmed = reader.readBool(offsets[5]);
  object.latitud = reader.readDoubleOrNull(offsets[6]);
  object.longitud = reader.readDoubleOrNull(offsets[7]);
  object.lugar = reader.readStringOrNull(offsets[8]);
  object.merchant = reader.readString(offsets[9]);
  object.notes = reader.readString(offsets[10]);
  object.precision = reader.readDoubleOrNull(offsets[11]);
  object.sourceName = reader.readString(offsets[12]);
  object.tarjeta = reader.readStringOrNull(offsets[13]);
  object.textoOriginal = reader.readString(offsets[14]);
  object.tipoName = reader.readString(offsets[15]);
  object.uuid = reader.readString(offsets[16]);
  return object;
}

P _expenseModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readDoubleOrNull(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _expenseModelGetId(ExpenseModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _expenseModelGetLinks(ExpenseModel object) {
  return [];
}

void _expenseModelAttach(
    IsarCollection<dynamic> col, Id id, ExpenseModel object) {
  object.id = id;
}

extension ExpenseModelQueryWhereSort
    on QueryBuilder<ExpenseModel, ExpenseModel, QWhere> {
  QueryBuilder<ExpenseModel, ExpenseModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ExpenseModelQueryWhere
    on QueryBuilder<ExpenseModel, ExpenseModel, QWhereClause> {
  QueryBuilder<ExpenseModel, ExpenseModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ExpenseModelQueryFilter
    on QueryBuilder<ExpenseModel, ExpenseModel, QFilterCondition> {
  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> amountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      amountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      amountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> amountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      canalNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'canalName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      canalNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'canalName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      canalNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'canalName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      canalNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'canalName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      canalNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'canalName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      canalNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'canalName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      canalNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'canalName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      canalNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'canalName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      canalNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'canalName',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      canalNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'canalName',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      categoryNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      categoryNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      categoryNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      categoryNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      categoryNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      categoryNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      categoryNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      categoryNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      categoryNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      categoryNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> dateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      estadoNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'estadoName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      estadoNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'estadoName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      estadoNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'estadoName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      estadoNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'estadoName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      estadoNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'estadoName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      estadoNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'estadoName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      estadoNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'estadoName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      estadoNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'estadoName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      estadoNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'estadoName',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      estadoNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'estadoName',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      isConfirmedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isConfirmed',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      latitudIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'latitud',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      latitudIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'latitud',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      latitudEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'latitud',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      latitudGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'latitud',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      latitudLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'latitud',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      latitudBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'latitud',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      longitudIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'longitud',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      longitudIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'longitud',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      longitudEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'longitud',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      longitudGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'longitud',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      longitudLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'longitud',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      longitudBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'longitud',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      lugarIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lugar',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      lugarIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lugar',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> lugarEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lugar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      lugarGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lugar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> lugarLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lugar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> lugarBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lugar',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      lugarStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lugar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> lugarEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lugar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> lugarContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lugar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> lugarMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lugar',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      lugarIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lugar',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      lugarIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lugar',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      merchantEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'merchant',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      merchantGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'merchant',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      merchantLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'merchant',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      merchantBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'merchant',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      merchantStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'merchant',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      merchantEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'merchant',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      merchantContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'merchant',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      merchantMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'merchant',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      merchantIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'merchant',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      merchantIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'merchant',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> notesEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      notesGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> notesLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> notesBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> notesContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> notesMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      precisionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'precision',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      precisionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'precision',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      precisionEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'precision',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      precisionGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'precision',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      precisionLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'precision',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      precisionBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'precision',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      sourceNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      sourceNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      sourceNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      sourceNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      sourceNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      sourceNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      sourceNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      sourceNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      sourceNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceName',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      sourceNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceName',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tarjetaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tarjeta',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tarjetaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tarjeta',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tarjetaEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tarjeta',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tarjetaGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tarjeta',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tarjetaLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tarjeta',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tarjetaBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tarjeta',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tarjetaStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tarjeta',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tarjetaEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tarjeta',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tarjetaContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tarjeta',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tarjetaMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tarjeta',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tarjetaIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tarjeta',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tarjetaIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tarjeta',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      textoOriginalEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textoOriginal',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      textoOriginalGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'textoOriginal',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      textoOriginalLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'textoOriginal',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      textoOriginalBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'textoOriginal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      textoOriginalStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'textoOriginal',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      textoOriginalEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'textoOriginal',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      textoOriginalContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'textoOriginal',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      textoOriginalMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'textoOriginal',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      textoOriginalIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textoOriginal',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      textoOriginalIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'textoOriginal',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tipoNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tipoName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tipoNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tipoName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tipoNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tipoName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tipoNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tipoName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tipoNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tipoName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tipoNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tipoName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tipoNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tipoName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tipoNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tipoName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tipoNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tipoName',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      tipoNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tipoName',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> uuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> uuidContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> uuidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }
}

extension ExpenseModelQueryObject
    on QueryBuilder<ExpenseModel, ExpenseModel, QFilterCondition> {}

extension ExpenseModelQueryLinks
    on QueryBuilder<ExpenseModel, ExpenseModel, QFilterCondition> {}

extension ExpenseModelQuerySortBy
    on QueryBuilder<ExpenseModel, ExpenseModel, QSortBy> {
  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByCanalName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canalName', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByCanalNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canalName', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      sortByCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByEstadoName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estadoName', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      sortByEstadoNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estadoName', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByIsConfirmed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isConfirmed', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      sortByIsConfirmedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isConfirmed', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByLatitud() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitud', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByLatitudDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitud', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByLongitud() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitud', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByLongitudDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitud', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByLugar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lugar', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByLugarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lugar', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByMerchant() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'merchant', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByMerchantDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'merchant', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByPrecision() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'precision', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByPrecisionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'precision', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortBySourceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceName', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      sortBySourceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceName', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByTarjeta() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tarjeta', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByTarjetaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tarjeta', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByTextoOriginal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textoOriginal', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      sortByTextoOriginalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textoOriginal', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByTipoName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipoName', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByTipoNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipoName', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension ExpenseModelQuerySortThenBy
    on QueryBuilder<ExpenseModel, ExpenseModel, QSortThenBy> {
  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByCanalName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canalName', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByCanalNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canalName', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      thenByCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByEstadoName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estadoName', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      thenByEstadoNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estadoName', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByIsConfirmed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isConfirmed', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      thenByIsConfirmedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isConfirmed', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByLatitud() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitud', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByLatitudDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitud', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByLongitud() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitud', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByLongitudDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitud', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByLugar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lugar', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByLugarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lugar', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByMerchant() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'merchant', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByMerchantDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'merchant', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByPrecision() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'precision', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByPrecisionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'precision', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenBySourceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceName', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      thenBySourceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceName', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByTarjeta() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tarjeta', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByTarjetaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tarjeta', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByTextoOriginal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textoOriginal', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      thenByTextoOriginalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textoOriginal', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByTipoName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipoName', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByTipoNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipoName', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension ExpenseModelQueryWhereDistinct
    on QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> {
  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByCanalName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'canalName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByCategoryName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByEstadoName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'estadoName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByIsConfirmed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isConfirmed');
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByLatitud() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latitud');
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByLongitud() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longitud');
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByLugar(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lugar', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByMerchant(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'merchant', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByPrecision() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'precision');
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctBySourceName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByTarjeta(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tarjeta', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByTextoOriginal(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'textoOriginal',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByTipoName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tipoName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension ExpenseModelQueryProperty
    on QueryBuilder<ExpenseModel, ExpenseModel, QQueryProperty> {
  QueryBuilder<ExpenseModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ExpenseModel, double, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<ExpenseModel, String, QQueryOperations> canalNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'canalName');
    });
  }

  QueryBuilder<ExpenseModel, String, QQueryOperations> categoryNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryName');
    });
  }

  QueryBuilder<ExpenseModel, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<ExpenseModel, String, QQueryOperations> estadoNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'estadoName');
    });
  }

  QueryBuilder<ExpenseModel, bool, QQueryOperations> isConfirmedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isConfirmed');
    });
  }

  QueryBuilder<ExpenseModel, double?, QQueryOperations> latitudProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latitud');
    });
  }

  QueryBuilder<ExpenseModel, double?, QQueryOperations> longitudProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longitud');
    });
  }

  QueryBuilder<ExpenseModel, String?, QQueryOperations> lugarProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lugar');
    });
  }

  QueryBuilder<ExpenseModel, String, QQueryOperations> merchantProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'merchant');
    });
  }

  QueryBuilder<ExpenseModel, String, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<ExpenseModel, double?, QQueryOperations> precisionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'precision');
    });
  }

  QueryBuilder<ExpenseModel, String, QQueryOperations> sourceNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceName');
    });
  }

  QueryBuilder<ExpenseModel, String?, QQueryOperations> tarjetaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tarjeta');
    });
  }

  QueryBuilder<ExpenseModel, String, QQueryOperations> textoOriginalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'textoOriginal');
    });
  }

  QueryBuilder<ExpenseModel, String, QQueryOperations> tipoNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tipoName');
    });
  }

  QueryBuilder<ExpenseModel, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
