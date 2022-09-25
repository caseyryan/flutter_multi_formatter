import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/utils/pinyin_utils.dart';

class PinyinFormatter implements TextInputFormatter {
  static final RegExp _apostropheRegexp = RegExp('\'');

  const PinyinFormatter();

  int _countSeparators(String value) {
    return _apostropheRegexp.allMatches(value).length;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final numOldSeparatos = _countSeparators(
      oldValue.text,
    );
    final newText = PinyinUtils.splitToSyllablesBySeparator(
      newValue.text.trim(),
      "'",
    );
    final numNewSeparatos = _countSeparators(
      newText,
    );
    final offset = newValue.selection.end + (numNewSeparatos - numOldSeparatos);
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: min(offset, newText.length),
      ),
    );
  }
}
