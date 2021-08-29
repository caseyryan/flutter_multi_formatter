/*
(c) Copyright 2020 Serov Konstantin.

Licensed under the MIT license:

    http://www.opensource.org/licenses/mit-license.php

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

import 'dart:math';

import 'package:flutter/services.dart';

class MaskedInputFormatter extends TextInputFormatter {
  final String mask;

  final String _anyCharMask = '#';
  final String _onlyDigitMask = '0';
  final RegExp? allowedCharMatcher;
  List<int> _separatorIndices = <int>[];
  List<String> _separatorChars = <String>[];
  String _maskedValue = '';

  /// [mask] is a string that must contain # (hash) and 0 (zero)
  /// as maskable characters. # means any possible character,
  /// 0 means only digits. So if you want to match e.g. a
  /// string like this GGG-FB-897-R5 you need
  /// a mask like this ###-##-000-#0
  /// a mask like ###-### will also match 123-034 but a mask like
  /// 000-000 will only match digits and won't allow a string like Gtt-RBB
  ///
  /// will match literally any character unless
  /// you supply an [allowedCharMatcher] parameter with a RegExp
  /// to constrain its values. e.g. RegExp(r'[a-z]+') will make #
  /// match only lowercase latin characters and everything else will be
  /// ignored
  MaskedInputFormatter(
    this.mask, {
    this.allowedCharMatcher,
  });

  bool get isFilled => _maskedValue.length == mask.length;

  String get unmaskedValue {
    _prepareMask();
    final stringBuffer = StringBuffer();
    for (var i = 0; i < _maskedValue.length; i++) {
      var char = _maskedValue[i];
      if (!_separatorChars.contains(char)) {
        stringBuffer.write(char);
      }
    }
    return stringBuffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final FormattedValue formattedValue = applyMask(
      newValue.text,
    );
    var selectionOffset =
        newValue.selection.end + formattedValue.selectionOffset;
    _maskedValue = formattedValue.toString();
    if (selectionOffset > _maskedValue.length) {
      selectionOffset = _maskedValue.length;
    }

    return TextEditingValue(
      text: _maskedValue,
      selection: TextSelection.collapsed(
        offset: selectionOffset,
      ),
    );
  }

  bool _isMatchingRestrictor(String character) {
    if (allowedCharMatcher == null) {
      return true;
    }
    return allowedCharMatcher!.stringMatch(character) != null;
  }

  void _prepareMask() {
    if (_separatorIndices.isEmpty) {
      for (var i = 0; i < mask.length; i++) {
        if (mask[i] != _anyCharMask && mask[i] != _onlyDigitMask) {
          _separatorIndices.add(i);
          _separatorChars.add(mask[i]);
        }
      }
    }
  }

  int _countSeparators(String text) {
    _prepareMask();
    var numSeparators = 0;
    for (var i = 0; i < text.length; i++) {
      if (_separatorChars.contains(text[i])) {
        numSeparators++;
      }
    }
    return numSeparators;
  }

  String _removeSeparators(String text) {
    var stringBuffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      var char = text[i];
      if (!_separatorChars.contains(char)) {
        stringBuffer.write(char);
      }
    }
    return stringBuffer.toString();
  }

  FormattedValue applyMask(String text) {
    _prepareMask();
    int numSeparatorsBefore = _countSeparators(text);
    String clearedValueAfter = _removeSeparators(text);
    final isErasing = _maskedValue.length > text.length;
    FormattedValue formattedValue = FormattedValue();
    StringBuffer stringBuffer = StringBuffer();
    var index = 0;
    var maxLength = min(
      clearedValueAfter.length,
      mask.length - _separatorChars.length,
    );

    for (var i = 0; i < maxLength; i++) {
      var curChar = clearedValueAfter[i];
      if (!_isMatchingRestrictor(curChar)) {
        continue;
      }
      if (_separatorIndices.contains(index)) {
        stringBuffer.write(mask[index]);
        index++;
      }
      stringBuffer.write(curChar);
      index++;
    }
    formattedValue._isErasing = isErasing;
    formattedValue._formattedValue = stringBuffer.toString();
    formattedValue._numSeparatorsAfter = _countSeparators(
      formattedValue._formattedValue,
    );
    formattedValue._numSeparatorsBefore = numSeparatorsBefore;
    return formattedValue;
  }
}

class FormattedValue {
  String _formattedValue = '';
  int _numSeparatorsBefore = 0;
  int _numSeparatorsAfter = 0;
  bool _isErasing = false;

  int get selectionOffset {
    final offset = (_numSeparatorsAfter - _numSeparatorsBefore).abs();
    return _isErasing ? 0 : offset;
  }

  @override
  String toString() {
    return _formattedValue;
  }
}
