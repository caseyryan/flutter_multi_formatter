# flutter_multi_formatter

This package contains formatters for international phone numbers, credit / debit cards, currencies and 
a masked formatter

Formatting a phone

<img src="https://github.com/caseyryan/flutter_multi_formatter/blob/master/phone_format.gif?raw=true" width="240"/>

Formatting a credit / debit card

<img src="https://github.com/caseyryan/flutter_multi_formatter/blob/master/card_format.gif?raw=true" width="240"/>

Formatting currencies

<img src="https://github.com/caseyryan/flutter_multi_formatter/blob/master/money_format.gif?raw=true" width="240"/>


## Using:
```dart
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
```


## A list of formatters included

```dart
/// for phone numbers with a fully automated detection
PhoneInputFormatter
/// for anything that can be masked
MaskedInputFormater
/// for credit / debit cards
CreditCardNumberFormatter
CvvCodeFormatter
CreditCardExpirationDateFormatter
CreditCardHolderNameFormatter
/// for currencies
MoneyInputFormatter
```

## Utility methods and widgets

gets all numbers out of a string and joins them into a new string
e.g. a string like fGgfjh456bb78 will be converted into this: 45678

```dart 
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

String toNumericString(String text);
```

return 'true' if the checked characted is digit
```dart 
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

bool isDigit(String character);
```

toCurrencyString() is used by the MoneyInputFormatter internally 
but you can also use it directly
```dart
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

String toCurrencyString(String value, {
    int mantissaLength = 2,
    ThousandSeparator thousandSeparator = ThousandSeparator.Comma,
    ShorteningPolicy shorteningPolicy = ShorteningPolicy.NoShortening,
    String leadingSymbol = '',
    String trailingSymbol = '',
    bool useSymbolPadding = false
});

print(toCurrencyString('123456', leadingSymbol: MoneyInputFormatter.DOLLAR_SIGN)); // $123,456.00

/// the values can also be shortened to thousands, millions, billions... 
/// in this case a 1000 will be displayed as 1K, and 1250000 will turn to this 1.25M
var result = toCurrencyString(
    '125000', 
    leadingSymbol: MoneyInputFormatter.DOLLAR_SIGN,
    shorteningPolicy: ShorteningPolicy.RoundToThousands
); // $125K

result = toCurrencyString(
    '1250000', 
    leadingSymbol: MoneyInputFormatter.DOLLAR_SIGN,
    shorteningPolicy: ShorteningPolicy.RoundToMillions
); // 1.25M

```
there's also an extension version of this function which can be used on 
double, int and String
but before using it, make sure you use dart sdk version 2.6+ 
open pubspec.yaml and check this section:
```
environment:
  sdk: ">=2.6.0 <3.0.0"
```

```dart
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

var someNumericValue = 123456;
print(someNumericValue.toCurrencyString(leadingSymbol: MoneyInputFormatter.DOLLAR_SIGN)); // $123,456.00

var someNumericStringValue = '123456';
print(someNumericStringValue.toCurrencyString(trailingSymbol: MoneyInputFormatter.EURO_SIGN)); // 123,456.00€

```


```dart 
/// it's a widget
Unfocuser
```
Unfocuser allows you to unfocus any text input and hide the onscreen keyboard 
when you tap outside of a text input. Use it like this:

```dart 
@override
Widget build(BuildContext context) {
return Unfocuser(
    child: Scaffold(
    body: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Form(
            key: _formKey,
            child: Column(
            children: <Widget>[
                TextFormField(
                keyboardType: TextInputType.phone,
                inputFormatters: [
                    PhoneInputFormatter()
                ],
                ),
            ],
            ),
        ),
        ),
    ),
    ),
);
}
```




### More detailed description

```dart
PhoneInputFormatter
```

automatically detects the country the phone number belongs to and formats the number according 
to its mask
you don't have to care about keeping track of the list of countries or anything else.
The whole process is completely automated
You simply add this formatter to the list of formatters like this:

```dart
TextFormField(
    keyboardType: TextInputType.phone,
    inputFormatters: [
        PhoneInputFormatter()
    ],
),
```

You can also get a country data for the selected phone number by simply passing a calback function to your 
formatter

```dart
TextFormField(
    keyboardType: TextInputType.phone,
    inputFormatters: [
        PhoneInputFormatter(onCountrySelected:  (PhoneCountryData countryData) {
            print(countryData.country);
        });
    ],
),
```

## Masked formatter

```dart
MaskedInputFormater
```
This formatter allows you to easily format a text by a mask
This formatter processes current text selection very carefully so that itput does not 
feel unnatural
Use it like any other formatters

```dart
/// # matches any character and 0 matches digits
/// so, in order to format a string like this GHJ45GHJHN to GHJ-45-GHJHN
/// use a mask like this
TextFormField(
    keyboardType: TextInputType.phone,
    inputFormatters: [
        MaskedInputFormater('###-00-#####')
    ],
),
```
But in case you want # (hash symbol) to match only some particular values, you can pass 
a regular expression to [anyCharMatcher] parameter

```dart
/// in this scenario, the # symbol will only match uppercase latin letters
TextFormField(
    keyboardType: TextInputType.phone,
    inputFormatters: [
        MaskedInputFormater('###-00-#####', anyCharMatcher: RegExp(r'[A-Z]'))
    ],
),
```
## Money Input formatter

```dart
MoneyInputFormatter
```

```dart
TextFormField(
    keyboardType: TextInputType.number,
    inputFormatters: [
        MoneyInputFormatter(
            leadingSymbol: MoneyInputFormatter.DOLLAR_SIGN
        )
    ],
),
...

TextFormField(
    keyboardType: TextInputType.number,
    inputFormatters: [
        MoneyInputFormatter(
            trailingSymbol: MoneyInputFormatter.EURO_SIGN,
            useSymbolPadding: true,
            mantissaLength: 3 // the length of the fractional side
        )
    ],
),

```



For more details see example project
