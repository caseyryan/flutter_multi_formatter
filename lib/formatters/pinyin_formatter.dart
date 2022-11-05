import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_multi_formatter/utils/pinyin_utils.dart';

class PinyinFormatter implements TextInputFormatter {
  static final RegExp _apostropheRegexp = RegExp('\'');
  static final RegExp _badApostrophes = RegExp(r"[’']+");

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
    String newText = newValue.text.replaceAll(_badApostrophes, '');
    final syllables = PinyinUtils.splitToSyllables<SyllableData>(
      newValue.text.trim(),
    );
    newText = syllables.map((e) => e.value).join('\'');
    if (newText.isEmpty) {
      newText = newValue.text;
    }
    if (newText.endsWith('\'')) {
      newText = newText.removeLast();
    }
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
