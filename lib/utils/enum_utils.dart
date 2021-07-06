import 'package:collection/collection.dart';

String? enumToString(dynamic enumValue) {
  if (enumValue == null) return null;
  return enumValue.toString().split('.')[1];
}

T? enumFromString<T>(List<T> enumValues, String? value) {
  if (value == null) return null;

  return enumValues.singleWhereOrNull(
    (enumItem) => enumToString(enumItem) == value,
  );
}