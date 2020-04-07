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