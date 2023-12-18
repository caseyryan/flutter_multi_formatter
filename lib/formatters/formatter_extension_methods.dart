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

import 'currency_input_formatter.dart';
import 'formatter_utils.dart' as fu;
import 'money_input_enums.dart';

/// WARNING! This stuff requires Dart SDK version 2.6+
/// so if your code is supposed to be running on
/// older versions do not use these methods!
/// or change the sdk restrictions in your pubspec.yaml like this:
/// environment:
///   sdk: ">=2.6.0 <3.0.0"

extension NumericInputFormatting on num {
  /// [thousandSeparator] specifies what symbol will be used to separate
  /// each block of 3 digits, e.g. [ThousandSeparator.Comma] will format
  /// a million as 1,000,000
  /// [shorteningPolicy] is used to round values using K for thousands, M for
  /// millions and B for billions
  /// [ShorteningPolicy.NoShortening] displays a value of 1234456789.34 as 1,234,456,789.34
  /// but [ShorteningPolicy.RoundToThousands] displays the same value as 1,234,456K
  /// [mantissaLength] specifies how many digits will be added after a period sign
  /// [leadingSymbol] any symbol (except for the ones that contain digits) the will be
  /// added in front of the resulting string. E.g. $ or €
  /// some of the signs are available via constants like [CurrencySymbols.EURO_SIGN]
  /// but you can basically add any string instead of it. The main rule is that the string
  /// must not contain digits, periods, commas and dashes
  /// [trailingSymbol] is the same as leading but this symbol will be added at the
  /// end of your resulting string like 1,250€ instead of €1,250
  /// [useSymbolPadding] adds a space between the number and trailing / leading symbols
  /// like 1,250€ -> 1,250 € or €1,250€ -> € 1,250
  String toCurrencyString({
    int mantissaLength = 2,
    ThousandSeparator thousandSeparator = ThousandSeparator.Comma,
    ShorteningPolicy shorteningPolicy = ShorteningPolicy.NoShortening,
    String leadingSymbol = '',
    String trailingSymbol = '',
    bool useSymbolPadding = false,
  }) {
    return fu.toCurrencyString(
      this.toString(),
      mantissaLength: mantissaLength,
      leadingSymbol: leadingSymbol,
      shorteningPolicy: shorteningPolicy,
      thousandSeparator: thousandSeparator,
      trailingSymbol: trailingSymbol,
      useSymbolPadding: useSymbolPadding,
    );
  }
}

extension StringInputFormatting on String {
  bool get isFiatCurrency {
    return fu.isFiatCurrency(this);
  }

  bool get isCryptoCurrency {
    return fu.isCryptoCurrency(this);
  }

  String reverse() {
    return split('').reversed.join();
  }

  String removeLast() {
    if (isEmpty) return this;
    return substring(0, length - 1);
  }

  /// [thousandSeparator] specifies what symbol will be used to separate
  /// each block of 3 digits, e.g. [ThousandSeparator.Comma] will format
  /// a million as 1,000,000
  /// [shorteningPolicy] is used to round values using K for thousands, M for
  /// millions and B for billions
  /// [ShorteningPolicy.NoShortening] displays a value of 1234456789.34 as 1,234,456,789.34
  /// but [ShorteningPolicy.RoundToThousands] displays the same value as 1,234,456K
  /// [mantissaLength] specifies how many digits will be added after a period sign
  /// [leadingSymbol] any symbol (except for the ones that contain digits) the will be
  /// added in front of the resulting string. E.g. $ or €
  /// some of the signs are available via constants like [MoneyInputFormatter.EURO_SIGN]
  /// but you can basically add any string instead of it. The main rule is that the string
  /// must not contain digits, periods, commas and dashes
  /// [trailingSymbol] is the same as leading but this symbol will be added at the
  /// end of your resulting string like 1,250€ instead of €1,250
  /// [useSymbolPadding] adds a space between the number and trailing / leading symbols
  /// like 1,250€ -> 1,250 € or €1,250€ -> € 1,250
  String toCurrencyString({
    int mantissaLength = 2,
    ThousandSeparator thousandSeparator = ThousandSeparator.Comma,
    ShorteningPolicy shorteningPolicy = ShorteningPolicy.NoShortening,
    String leadingSymbol = '',
    String trailingSymbol = '',
    bool useSymbolPadding = false,
  }) {
    return fu.toCurrencyString(
      toString(),
      mantissaLength: mantissaLength,
      leadingSymbol: leadingSymbol,
      shorteningPolicy: shorteningPolicy,
      thousandSeparator: thousandSeparator,
      trailingSymbol: trailingSymbol,
      useSymbolPadding: useSymbolPadding,
    );
  }
}
