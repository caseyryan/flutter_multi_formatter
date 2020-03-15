# flutter_multi_formatter

This package contains a few useful input formatters and utility methods 

Formatting a phone

<img src="https://github.com/caseyryan/flutter_multi_formatter/blob/master/phone_format.gif?raw=true" width="240"/>

Formatting a credint / debit card

<img src="https://github.com/caseyryan/flutter_multi_formatter/blob/master/card_format.gif?raw=true" width="240"/>


## using:
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
```

## Utility methods and widgets

```dart 
String toNumericString(String text);
```
gets all numbers out of a string and joins them into a new string
e.g. a string like fGgfjh456bb78 will be converted into this: 45678

```dart 
bool isDigit(String character);
```
return 'true' if the checked characted is digit

```dart 
/// a widget
Unfocuser
```
This allows you to unfocus any text input and hide the keyboard 
when you type outside a text input. Use it like this:

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

For more details see example project
