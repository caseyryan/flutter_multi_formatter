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
final RegExp _digitRegex = RegExp(r'[-0-9]+');
final RegExp _positiveDigitRegex = RegExp(r'[0-9]+');
final RegExp _digitWithPeriodRegex = RegExp(r'[-0-9]+(\.[0-9]+)?');
final RegExp _oneDashRegExp = RegExp(r'[-]{2,}');

String toNumericString(
  String inputString, {
  bool allowPeriod = false,
  bool allowHyphen = true,
}) {
  if (inputString == null) return '';
  var regexWithoutPeriod = allowHyphen ? _digitRegex : _positiveDigitRegex;
  var regExp = allowPeriod ? _digitWithPeriodRegex : regexWithoutPeriod;
  return inputString.splitMapJoin(regExp,
      onMatch: (m) => m.group(0), onNonMatch: (nm) => '');
}

void checkMask(String mask) {
  var _oneDashRegExp = RegExp(r'[-]{2,}');
  if (_oneDashRegExp.hasMatch(mask)) {
    throw('A mask cannot contain more than one dash (-) symbols in a row');
    // return false;
  }
  var _startPlusRegExp = RegExp(r'^\+{1}[)(\d]+');
  if (!_startPlusRegExp.hasMatch(mask)) {
    throw('A mask must start with a + sign followed by a digit of a rounded brace');
  }
  var _maskContentsRegexp = RegExp(r'^[-0-9)( +]{3,}$');
  if (!_maskContentsRegexp.hasMatch(mask)) {
    throw('A mask can only contain digits, a plus sign, spaces and dashes');
  }
}

bool isDigit(String character) {
  if (character == null || character.isEmpty || character.length > 1) {
    return false;
  }
  return _digitRegex.stringMatch(character) != null;
}
