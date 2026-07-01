// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_settings.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBusinessSettingsCollection on Isar {
  IsarCollection<BusinessSettings> get businessSettings => this.collection();
}

const BusinessSettingsSchema = CollectionSchema(
  name: r'BusinessSettings',
  id: -4971945712468206470,
  properties: {
    r'address': PropertySchema(id: 0, name: r'address', type: IsarType.string),
    r'allowSellWhenOutOfStock': PropertySchema(
      id: 1,
      name: r'allowSellWhenOutOfStock',
      type: IsarType.bool,
    ),
    r'businessName': PropertySchema(
      id: 2,
      name: r'businessName',
      type: IsarType.string,
    ),
    r'businessType': PropertySchema(
      id: 3,
      name: r'businessType',
      type: IsarType.string,
    ),
    r'categories': PropertySchema(
      id: 4,
      name: r'categories',
      type: IsarType.stringList,
    ),
    r'completedChecklistItems': PropertySchema(
      id: 5,
      name: r'completedChecklistItems',
      type: IsarType.stringList,
    ),
    r'currency': PropertySchema(
      id: 6,
      name: r'currency',
      type: IsarType.string,
    ),
    r'email': PropertySchema(id: 7, name: r'email', type: IsarType.string),
    r'includeUnpaidInReports': PropertySchema(
      id: 8,
      name: r'includeUnpaidInReports',
      type: IsarType.bool,
    ),
    r'isDirty': PropertySchema(id: 9, name: r'isDirty', type: IsarType.bool),
    r'logoPath': PropertySchema(
      id: 10,
      name: r'logoPath',
      type: IsarType.string,
    ),
    r'phone': PropertySchema(id: 11, name: r'phone', type: IsarType.string),
    r'receiptQrLink': PropertySchema(
      id: 12,
      name: r'receiptQrLink',
      type: IsarType.string,
    ),
    r'themeColor': PropertySchema(
      id: 13,
      name: r'themeColor',
      type: IsarType.string,
    ),
    r'timezone': PropertySchema(
      id: 14,
      name: r'timezone',
      type: IsarType.string,
    ),
    r'trackPartialChange': PropertySchema(
      id: 15,
      name: r'trackPartialChange',
      type: IsarType.bool,
    ),
    r'uid': PropertySchema(id: 16, name: r'uid', type: IsarType.string),
    r'updatedAt': PropertySchema(
      id: 17,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'workflowStages': PropertySchema(
      id: 18,
      name: r'workflowStages',
      type: IsarType.stringList,
    ),
  },

  estimateSize: _businessSettingsEstimateSize,
  serialize: _businessSettingsSerialize,
  deserialize: _businessSettingsDeserialize,
  deserializeProp: _businessSettingsDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _businessSettingsGetId,
  getLinks: _businessSettingsGetLinks,
  attach: _businessSettingsAttach,
  version: '3.3.2',
);

int _businessSettingsEstimateSize(
  BusinessSettings object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.address;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.businessName.length * 3;
  bytesCount += 3 + object.businessType.length * 3;
  bytesCount += 3 + object.categories.length * 3;
  {
    for (var i = 0; i < object.categories.length; i++) {
      final value = object.categories[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.completedChecklistItems.length * 3;
  {
    for (var i = 0; i < object.completedChecklistItems.length; i++) {
      final value = object.completedChecklistItems[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.currency.length * 3;
  {
    final value = object.email;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.logoPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.phone;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.receiptQrLink;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.themeColor.length * 3;
  bytesCount += 3 + object.timezone.length * 3;
  bytesCount += 3 + object.uid.length * 3;
  bytesCount += 3 + object.workflowStages.length * 3;
  {
    for (var i = 0; i < object.workflowStages.length; i++) {
      final value = object.workflowStages[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _businessSettingsSerialize(
  BusinessSettings object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.address);
  writer.writeBool(offsets[1], object.allowSellWhenOutOfStock);
  writer.writeString(offsets[2], object.businessName);
  writer.writeString(offsets[3], object.businessType);
  writer.writeStringList(offsets[4], object.categories);
  writer.writeStringList(offsets[5], object.completedChecklistItems);
  writer.writeString(offsets[6], object.currency);
  writer.writeString(offsets[7], object.email);
  writer.writeBool(offsets[8], object.includeUnpaidInReports);
  writer.writeBool(offsets[9], object.isDirty);
  writer.writeString(offsets[10], object.logoPath);
  writer.writeString(offsets[11], object.phone);
  writer.writeString(offsets[12], object.receiptQrLink);
  writer.writeString(offsets[13], object.themeColor);
  writer.writeString(offsets[14], object.timezone);
  writer.writeBool(offsets[15], object.trackPartialChange);
  writer.writeString(offsets[16], object.uid);
  writer.writeDateTime(offsets[17], object.updatedAt);
  writer.writeStringList(offsets[18], object.workflowStages);
}

BusinessSettings _businessSettingsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BusinessSettings();
  object.address = reader.readStringOrNull(offsets[0]);
  object.allowSellWhenOutOfStock = reader.readBool(offsets[1]);
  object.businessName = reader.readString(offsets[2]);
  object.businessType = reader.readString(offsets[3]);
  object.categories = reader.readStringList(offsets[4]) ?? [];
  object.completedChecklistItems = reader.readStringList(offsets[5]) ?? [];
  object.currency = reader.readString(offsets[6]);
  object.email = reader.readStringOrNull(offsets[7]);
  object.id = id;
  object.includeUnpaidInReports = reader.readBool(offsets[8]);
  object.isDirty = reader.readBool(offsets[9]);
  object.logoPath = reader.readStringOrNull(offsets[10]);
  object.phone = reader.readStringOrNull(offsets[11]);
  object.receiptQrLink = reader.readStringOrNull(offsets[12]);
  object.themeColor = reader.readString(offsets[13]);
  object.timezone = reader.readString(offsets[14]);
  object.trackPartialChange = reader.readBool(offsets[15]);
  object.uid = reader.readString(offsets[16]);
  object.updatedAt = reader.readDateTime(offsets[17]);
  object.workflowStages = reader.readStringList(offsets[18]) ?? [];
  return object;
}

P _businessSettingsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringList(offset) ?? []) as P;
    case 5:
      return (reader.readStringList(offset) ?? []) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readBool(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readDateTime(offset)) as P;
    case 18:
      return (reader.readStringList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _businessSettingsGetId(BusinessSettings object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _businessSettingsGetLinks(BusinessSettings object) {
  return [];
}

void _businessSettingsAttach(
  IsarCollection<dynamic> col,
  Id id,
  BusinessSettings object,
) {
  object.id = id;
}

extension BusinessSettingsQueryWhereSort
    on QueryBuilder<BusinessSettings, BusinessSettings, QWhere> {
  QueryBuilder<BusinessSettings, BusinessSettings, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension BusinessSettingsQueryWhere
    on QueryBuilder<BusinessSettings, BusinessSettings, QWhereClause> {
  QueryBuilder<BusinessSettings, BusinessSettings, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterWhereClause>
  idNotEqualTo(Id id) {
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

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension BusinessSettingsQueryFilter
    on QueryBuilder<BusinessSettings, BusinessSettings, QFilterCondition> {
  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  addressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'address'),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  addressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'address'),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  addressEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  addressGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  addressLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  addressBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'address',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  addressStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  addressEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  addressContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  addressMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'address',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  addressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'address', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  addressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'address', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  allowSellWhenOutOfStockEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'allowSellWhenOutOfStock',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  businessNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'businessName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  businessNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'businessName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  businessNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'businessName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  businessNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'businessName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  businessNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'businessName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  businessNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'businessName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  businessNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'businessName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  businessNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'businessName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  businessNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'businessName', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  businessNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'businessName', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  businessTypeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'businessType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  businessTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'businessType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  businessTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'businessType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  businessTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'businessType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  businessTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'businessType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  businessTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'businessType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  businessTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'businessType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  businessTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'businessType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  businessTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'businessType', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  businessTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'businessType', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  categoriesElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'categories',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  categoriesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'categories',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  categoriesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'categories',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  categoriesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'categories',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  categoriesElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'categories',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  categoriesElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'categories',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  categoriesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'categories',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  categoriesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'categories',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  categoriesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'categories', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  categoriesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'categories', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  categoriesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'categories', length, true, length, true);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  categoriesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'categories', 0, true, 0, true);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  categoriesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'categories', 0, false, 999999, true);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  categoriesLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'categories', 0, true, length, include);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  categoriesLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'categories', length, include, 999999, true);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  categoriesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'categories',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  completedChecklistItemsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'completedChecklistItems',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  completedChecklistItemsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'completedChecklistItems',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  completedChecklistItemsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'completedChecklistItems',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  completedChecklistItemsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'completedChecklistItems',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  completedChecklistItemsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'completedChecklistItems',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  completedChecklistItemsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'completedChecklistItems',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  completedChecklistItemsElementContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'completedChecklistItems',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  completedChecklistItemsElementMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'completedChecklistItems',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  completedChecklistItemsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'completedChecklistItems',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  completedChecklistItemsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'completedChecklistItems',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  completedChecklistItemsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'completedChecklistItems',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  completedChecklistItemsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'completedChecklistItems', 0, true, 0, true);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  completedChecklistItemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'completedChecklistItems',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  completedChecklistItemsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'completedChecklistItems',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  completedChecklistItemsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'completedChecklistItems',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  completedChecklistItemsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'completedChecklistItems',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  currencyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'currency',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  currencyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'currency',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  currencyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'currency',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  currencyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'currency',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  currencyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'currency',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  currencyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'currency',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  currencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'currency',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  currencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'currency',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  currencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'currency', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  currencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'currency', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  emailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'email'),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  emailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'email'),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  emailEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'email',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  emailGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'email',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  emailLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'email',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  emailBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'email',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  emailStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'email',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  emailEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'email',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  emailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'email',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  emailMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'email',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  emailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'email', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  emailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'email', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  includeUnpaidInReportsEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'includeUnpaidInReports',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  isDirtyEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isDirty', value: value),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  logoPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'logoPath'),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  logoPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'logoPath'),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  logoPathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'logoPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  logoPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'logoPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  logoPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'logoPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  logoPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'logoPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  logoPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'logoPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  logoPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'logoPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  logoPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'logoPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  logoPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'logoPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  logoPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'logoPath', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  logoPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'logoPath', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  phoneIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'phone'),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  phoneIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'phone'),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  phoneEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'phone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  phoneGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'phone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  phoneLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'phone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  phoneBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'phone',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  phoneStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'phone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  phoneEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'phone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  phoneContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'phone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  phoneMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'phone',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  phoneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'phone', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  phoneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'phone', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  receiptQrLinkIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'receiptQrLink'),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  receiptQrLinkIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'receiptQrLink'),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  receiptQrLinkEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'receiptQrLink',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  receiptQrLinkGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'receiptQrLink',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  receiptQrLinkLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'receiptQrLink',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  receiptQrLinkBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'receiptQrLink',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  receiptQrLinkStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'receiptQrLink',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  receiptQrLinkEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'receiptQrLink',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  receiptQrLinkContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'receiptQrLink',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  receiptQrLinkMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'receiptQrLink',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  receiptQrLinkIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'receiptQrLink', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  receiptQrLinkIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'receiptQrLink', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  themeColorEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'themeColor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  themeColorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'themeColor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  themeColorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'themeColor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  themeColorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'themeColor',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  themeColorStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'themeColor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  themeColorEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'themeColor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  themeColorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'themeColor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  themeColorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'themeColor',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  themeColorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'themeColor', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  themeColorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'themeColor', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  timezoneEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'timezone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  timezoneGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'timezone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  timezoneLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'timezone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  timezoneBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'timezone',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  timezoneStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'timezone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  timezoneEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'timezone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  timezoneContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'timezone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  timezoneMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'timezone',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  timezoneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'timezone', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  timezoneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'timezone', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  trackPartialChangeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'trackPartialChange', value: value),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  uidEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  uidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  uidLessThan(String value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  uidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  uidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  uidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  uidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  uidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uid', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uid', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  updatedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  workflowStagesElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'workflowStages',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  workflowStagesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'workflowStages',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  workflowStagesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'workflowStages',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  workflowStagesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'workflowStages',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  workflowStagesElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'workflowStages',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  workflowStagesElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'workflowStages',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  workflowStagesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'workflowStages',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  workflowStagesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'workflowStages',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  workflowStagesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'workflowStages', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  workflowStagesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'workflowStages', value: ''),
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  workflowStagesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'workflowStages', length, true, length, true);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  workflowStagesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'workflowStages', 0, true, 0, true);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  workflowStagesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'workflowStages', 0, false, 999999, true);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  workflowStagesLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'workflowStages', 0, true, length, include);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  workflowStagesLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'workflowStages', length, include, 999999, true);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterFilterCondition>
  workflowStagesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'workflowStages',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension BusinessSettingsQueryObject
    on QueryBuilder<BusinessSettings, BusinessSettings, QFilterCondition> {}

extension BusinessSettingsQueryLinks
    on QueryBuilder<BusinessSettings, BusinessSettings, QFilterCondition> {}

extension BusinessSettingsQuerySortBy
    on QueryBuilder<BusinessSettings, BusinessSettings, QSortBy> {
  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByAllowSellWhenOutOfStock() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowSellWhenOutOfStock', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByAllowSellWhenOutOfStockDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowSellWhenOutOfStock', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByBusinessName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessName', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByBusinessNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessName', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByBusinessType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessType', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByBusinessTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessType', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy> sortByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByIncludeUnpaidInReports() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includeUnpaidInReports', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByIncludeUnpaidInReportsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includeUnpaidInReports', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByIsDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDirty', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByIsDirtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDirty', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByLogoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logoPath', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByLogoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logoPath', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy> sortByPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phone', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phone', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByReceiptQrLink() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptQrLink', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByReceiptQrLinkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptQrLink', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByThemeColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeColor', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByThemeColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeColor', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByTimezone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timezone', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByTimezoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timezone', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByTrackPartialChange() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackPartialChange', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByTrackPartialChangeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackPartialChange', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy> sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension BusinessSettingsQuerySortThenBy
    on QueryBuilder<BusinessSettings, BusinessSettings, QSortThenBy> {
  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByAllowSellWhenOutOfStock() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowSellWhenOutOfStock', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByAllowSellWhenOutOfStockDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowSellWhenOutOfStock', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByBusinessName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessName', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByBusinessNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessName', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByBusinessType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessType', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByBusinessTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessType', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy> thenByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByIncludeUnpaidInReports() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includeUnpaidInReports', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByIncludeUnpaidInReportsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includeUnpaidInReports', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByIsDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDirty', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByIsDirtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDirty', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByLogoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logoPath', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByLogoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logoPath', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy> thenByPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phone', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phone', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByReceiptQrLink() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptQrLink', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByReceiptQrLinkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptQrLink', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByThemeColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeColor', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByThemeColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeColor', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByTimezone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timezone', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByTimezoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timezone', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByTrackPartialChange() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackPartialChange', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByTrackPartialChangeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackPartialChange', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy> thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension BusinessSettingsQueryWhereDistinct
    on QueryBuilder<BusinessSettings, BusinessSettings, QDistinct> {
  QueryBuilder<BusinessSettings, BusinessSettings, QDistinct>
  distinctByAddress({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'address', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QDistinct>
  distinctByAllowSellWhenOutOfStock() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'allowSellWhenOutOfStock');
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QDistinct>
  distinctByBusinessName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'businessName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QDistinct>
  distinctByBusinessType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'businessType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QDistinct>
  distinctByCategories() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categories');
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QDistinct>
  distinctByCompletedChecklistItems() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedChecklistItems');
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QDistinct>
  distinctByCurrency({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QDistinct> distinctByEmail({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'email', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QDistinct>
  distinctByIncludeUnpaidInReports() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'includeUnpaidInReports');
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QDistinct>
  distinctByIsDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDirty');
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QDistinct>
  distinctByLogoPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'logoPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QDistinct> distinctByPhone({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'phone', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QDistinct>
  distinctByReceiptQrLink({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'receiptQrLink',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QDistinct>
  distinctByThemeColor({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'themeColor', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QDistinct>
  distinctByTimezone({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timezone', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QDistinct>
  distinctByTrackPartialChange() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trackPartialChange');
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QDistinct> distinctByUid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<BusinessSettings, BusinessSettings, QDistinct>
  distinctByWorkflowStages() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'workflowStages');
    });
  }
}

extension BusinessSettingsQueryProperty
    on QueryBuilder<BusinessSettings, BusinessSettings, QQueryProperty> {
  QueryBuilder<BusinessSettings, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BusinessSettings, String?, QQueryOperations> addressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'address');
    });
  }

  QueryBuilder<BusinessSettings, bool, QQueryOperations>
  allowSellWhenOutOfStockProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'allowSellWhenOutOfStock');
    });
  }

  QueryBuilder<BusinessSettings, String, QQueryOperations>
  businessNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'businessName');
    });
  }

  QueryBuilder<BusinessSettings, String, QQueryOperations>
  businessTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'businessType');
    });
  }

  QueryBuilder<BusinessSettings, List<String>, QQueryOperations>
  categoriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categories');
    });
  }

  QueryBuilder<BusinessSettings, List<String>, QQueryOperations>
  completedChecklistItemsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedChecklistItems');
    });
  }

  QueryBuilder<BusinessSettings, String, QQueryOperations> currencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currency');
    });
  }

  QueryBuilder<BusinessSettings, String?, QQueryOperations> emailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'email');
    });
  }

  QueryBuilder<BusinessSettings, bool, QQueryOperations>
  includeUnpaidInReportsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'includeUnpaidInReports');
    });
  }

  QueryBuilder<BusinessSettings, bool, QQueryOperations> isDirtyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDirty');
    });
  }

  QueryBuilder<BusinessSettings, String?, QQueryOperations> logoPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'logoPath');
    });
  }

  QueryBuilder<BusinessSettings, String?, QQueryOperations> phoneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'phone');
    });
  }

  QueryBuilder<BusinessSettings, String?, QQueryOperations>
  receiptQrLinkProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receiptQrLink');
    });
  }

  QueryBuilder<BusinessSettings, String, QQueryOperations>
  themeColorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'themeColor');
    });
  }

  QueryBuilder<BusinessSettings, String, QQueryOperations> timezoneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timezone');
    });
  }

  QueryBuilder<BusinessSettings, bool, QQueryOperations>
  trackPartialChangeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trackPartialChange');
    });
  }

  QueryBuilder<BusinessSettings, String, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }

  QueryBuilder<BusinessSettings, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<BusinessSettings, List<String>, QQueryOperations>
  workflowStagesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workflowStages');
    });
  }
}
