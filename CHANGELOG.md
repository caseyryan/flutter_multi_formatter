## [1.3.0]
- Added RestrictingInputFormatter that allows to restrict or to allow 
some characters in an input field
## [1.2.3]
- Added a possibility to limit text length while formatting
## [1.2.2]
- Fixed a bug with inability to enter a text when in was first empty
## [1.2.1]
- Flutter version lowered to 1.22.3
## [1.2.0]
- Fixed an issue with double zeroes when applying more period after erasing
- Fixed a bug with format when using periods as thousand separators. Now 
the automatic formatting does not depend on whether you select commas or periods 
- Now the text is formatting not only while typing but also when erasing
- The plugin now requires a minumum version of flutter 1.22.4 because 
of a critical but with a base TextInputFormatter in previous releases and 
dart sdk 2.10.2 or newer. Sorry for this but it was really necessary
- Added more money symbols. Now there are stored in string constants inside 
MoneySymbols class. Just use MoneySymbols.BITCOIN_SIGN if you need Ƀ for example
- Fixed some phone masks for different countries

## [1.1.8]
- Apllied some formatting
## [1.1.7]

- Phone maskes now are not restricted by length. The number is masked as before
and a country is detected but now you can enter any number of digits after the 
mask if filled. This is necessary for some countries that have a 
variable number of digits in their phone numbers e.g. Estonia

## [1.1.6]

- Added a possibility to use a period as a thousand separator

## [1.1.5]

- Added support for 6 card systems for now. If the card number is detected 
as one of the supported systems, e.g. Mastercard, it will be formatted automatically
and the callback with CardSystemData argument will be called
- CreditCardHolderNameFormatter was completely removed. There's no need for this formatter
- CreditCardNumberFormatter was replaced with CreditCardNumberInputFormatter which is more flexible
- CvvCodeFormatter was renamed to CreditCardCvcInputFormatter
- CreditCardExpirationDateFormatter was renamed to CreditCardExpirationDateFormatter


## [1.1.1]

- Fixed a bug in masked input formatter which allowed to enter an odd symbol 
in some circumstances

## [1.1.0]

- Added MoneyInputFormatter

## [1.0.3]

- Initial pub release. Includes a list of formatters:

PhoneInputFormatter
MaskedInputFormater
CreditCardNumberFormatter
CvvCodeFormatter
CreditCardExpirationDateFormatter
CreditCardHolderNameFormatter