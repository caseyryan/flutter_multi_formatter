# flutter_multi_formatter

This package contains formatters for international phone numbers, credit / debit cards, currencies and 
a masked formatter
https://pub.dev/packages/flutter_multi_formatter

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
CreditCardNumberInputFormatter
CreditCardCvcInputFormatter
CreditCardExpirationDateFormatter
/// for any inputs where you need to restrict or
/// allow some characters
RestrictingInputFormatter
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

returns 'true' if the checked characted is digit

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
    /// in case you need a period as a thousand separator
    /// simply change ThousandSeparator.Comma to ThousandSeparator.Period
    /// and you will get 1.000.000,00 instead of 1,000,000.00
    ThousandSeparator thousandSeparator = ThousandSeparator.Comma,
    ShorteningPolicy shorteningPolicy = ShorteningPolicy.NoShortening,
    String leadingSymbol = '',
    String trailingSymbol = '',
    bool useSymbolPadding = false
});

print(toCurrencyString('123456', leadingSymbol: MoneySymbols.DOLLAR_SIGN)); // $123,456.00

/// the values can also be shortened to thousands, millions, billions... 
/// in this case a 1000 will be displayed as 1K, and 1250000 will turn to this 1.25M
var result = toCurrencyString(
    '125000', 
    leadingSymbol: MoneySymbols.DOLLAR_SIGN,
    shorteningPolicy: ShorteningPolicy.RoundToThousands
); // $125K

result = toCurrencyString(
    '1250000', 
    leadingSymbol: MoneySymbols.DOLLAR_SIGN,
    shorteningPolicy: ShorteningPolicy.RoundToMillions
); // 1.25M

```
there's also an extension version of this function which can be used on 
double, int and String
but before using it, make sure you use dart sdk version 2.6+ 
open pubspec.yaml and check this section:
```
environment:
  sdk: ">=2.10.2 <3.0.0"
```

```dart
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

var someNumericValue = 123456;
print(someNumericValue.toCurrencyString(leadingSymbol: MoneySymbols.DOLLAR_SIGN)); // $123,456.00

var someNumericStringValue = '123456';
print(someNumericStringValue.toCurrencyString(trailingSymbol: MoneySymbols.EURO_SIGN)); // 123,456.00€

```

## Restrict characters in a string

You can also restrict some characters or allow them. 
For this purpose use RestrictingInputFormatter.restrictFromString() 
and RestrictingInputFormatter.allowFromString() constructors 

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
                    /// this will not allow to enter any 
                    /// characters contained in restrictedChars string
                    /// notice that you need to excape two characters only
                    /// A backslash \\ and the second is dollar sign \$
                    /// other chars do not have to be excaped
                    RestrictingInputFormatter
                        .restrictFromString(restrictedChars: ';^\\\$()[](){}*|/',
                    )
                    ]
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

## Allow characters in a string
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
                    /// it works exactly the same as restrictFromString 
                    /// but the other way round. It will only allow to enter 
                    /// the characters from the string
                    RestrictingInputFormatter
                        .allowFromString(allowedChars: ';^\\\$()[](){}*|/',
                    )
                    ]
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

```dart
CreditCardNumberInputFormatter
```
CreditCardNumberInputFormatter automatically detects a type of a card based on a predefined 
list of card system and formats the number accordingly. 
This detection is pretty rough and may not work with many card system. 
All supported systems are available as string constants in 

```dart
class CardSystem {
  static const String VISA = 'Visa';
  static const String MASTERCARD = 'Mastercard';
  static const String JCB = 'JCB';
  static const String DISCOVER = 'Discover';
  static const String MAESTRO = 'Maestro';
  static const String AMERICAN_EXPRESS= 'Amex';
}
```
Anyway, if the number is not supported it will just be returned as is and your input will not 
break because of that


```dart
TextFormField(
    keyboardType: TextInputType.number,
    inputFormatters: [
        CreditCardNumberInputFormatter(onCardSystemSelected:  (CardSystemData cardSystemData) {
            print(cardSystemData.system);
        });
    ],
),

/// there's also a method to format a number as a card number
/// the method is located in a credit_card_number_input_formatter.dart file
String formatAsCardNumber(
String cardNumber, {
    bool useSeparators = true,
});

/// and a method to check is a card is valid
bool isCardValidNumber(String cardNumber);
/// but it will return true only if the card system is supported, 
/// so you should not really rely on that

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
            leadingSymbol: MoneySymbols.DOLLAR_SIGN
        )
    ],
),
...

TextFormField(
    keyboardType: TextInputType.number,
    inputFormatters: [
        MoneyInputFormatter(
            trailingSymbol: MoneySymbols.EURO_SIGN,
            useSymbolPadding: true,
            mantissaLength: 3 // the length of the fractional side
        )
    ],
),

```



For more details see example project. And feel free to open an issue if you find any bugs of errors
