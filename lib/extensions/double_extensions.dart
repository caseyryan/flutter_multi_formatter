import 'package:flutter/foundation.dart';

extension DoubleExtensions on double {
  String toStringAsSmartRound({
    int maxPrecision = 2,
  }) {
    final str = toString();
    try {
      if (str.contains('.')) {
        final split = str.split('');
        final mantissa = <String>[];
        final periodIndex = str.indexOf('.');
        final wholePart = str.substring(0, periodIndex);
        int numChars = 0;
        for (var i = periodIndex + 1; i < str.length; i++) {
          if (numChars >= maxPrecision) {
            break;
          }
          final char = split[i];
          // if (char == '0') {
          //   break;
          // } else {
          mantissa.add(char);
          // }
          numChars++;
        }
        if (mantissa.isNotEmpty) {
          int i = mantissa.length - 1;
          while (mantissa.isNotEmpty) {
            if (mantissa[i] != '0') {
              break;
            }
            i--;
            mantissa.removeLast();
          }
          if (mantissa.isNotEmpty) {
            return '$wholePart.${mantissa.join()}';
          }
        }
        return wholePart;
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return str;
  }

  int toSafeInt({
    int? minValue,
    int? maxValue,
  }) {
    if (minValue == null && maxValue == null) {
      return toInt();
    }
    if (minValue != null) {
      if (this < minValue) {
        return minValue;
      }
    }
    if (maxValue != null) {
      if (this > maxValue) {
        return maxValue;
      }
    }
    return toInt();
  }
}
