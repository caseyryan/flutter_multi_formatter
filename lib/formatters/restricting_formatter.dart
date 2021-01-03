import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class RestrictingInputFormatter extends TextInputFormatter {
  RegExp _restrictor;
  bool _allow;

  RestrictingInputFormatter._internal();

  /// Builds a restrictor based on a
  /// string of restricted characters
  /// [restrictedChars] a string containing all characters
  /// that will be restricted. E.g. "()*^%#"
  @Deprecated('Use a Flutter\'s build-in FilteringTextInputFormatter instead')
  factory RestrictingInputFormatter.restrictFromString({
    @required String restrictedChars,
  }) {
    assert(restrictedChars != null && restrictedChars.isNotEmpty);
    var formatter = RestrictingInputFormatter._internal();
    formatter._allow = false;
    restrictedChars = formatter._escape(restrictedChars);
    formatter._restrictor = RegExp("[$restrictedChars]+");
    return formatter;
  }

  /// Use this restrictor if you want to allow only values from
  /// string
  /// [allowedChars] as string with allowed characters
  /// e.g. "&w4" will allow only ampersands w's and fours
  factory RestrictingInputFormatter.allowFromString({
    @required String allowedChars,
  }) {
    assert(allowedChars != null && allowedChars.isNotEmpty);
    var formatter = RestrictingInputFormatter._internal();
    formatter._allow = true;
    allowedChars = formatter._escape(allowedChars);
    formatter._restrictor = RegExp("[$allowedChars]+");
    return formatter;
  }

  String _escapeSpecialChar(String char) {
    switch (char) {
      case '[':
      case ']':
      case '(':
      case ')':
      case '^':
      case '.':
        return '\\$char';
    }
    return char;
  }

  String _escape(String text) {
    var hashSet = HashSet<String>();
    var containsSlash = text.contains('\\');
    text = text.replaceAll(RegExp(r'[\\]+'), '');
    for (var i = 0; i < text.length; i++) {
      var char = text[i];
      hashSet.add(_escapeSpecialChar(char));
    }

    var filteredString = hashSet.join('');
    if (containsSlash) {
      /// a small hach to avoid exception when
      /// building a regular expression from string
      filteredString += '\\';
      filteredString += '\\';
    }
    return filteredString;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var selection = newValue.selection;
    var newText = newValue.text;
    if (!_allow) {
      if (_restrictor.hasMatch(newValue.text)) {
        newText = newValue.text.replaceAll(_restrictor, '');
      }
    } else {
      newText = _restrictor
          .allMatches(newValue.text)
          .map(
            (e) => newValue.text.substring(e.start, e.end),
          )
          .join('');
    }
    selection = newValue.selection;
    if (selection.end >= newText.length) {
      selection = selection.copyWith(
        baseOffset: newText.length,
        extentOffset: newText.length,
      );
    }
    return TextEditingValue(
      text: newText,
      selection: selection,
    );
  }
}
